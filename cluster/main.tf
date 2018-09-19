terraform {
  required_version = "> 0.8.0"
}

### NOTE: Do not change the layout of the template files or your will get unnecessary empty lines
###       in the generated output.

data "aws_vpc" "vpc_for_k8s" {
  id = "${var.vpc_id}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "kubernetes_ami" {
  most_recent = true

  # ebs-kubernetes-baseimage-1.7-201712051032
  # This is a pre build image base on https://github.com/skyscrapers/kubernetes-baseimage
  name_regex = "^ebs-kubernetes-baseimage-${element(split(".",var.k8s_version),0)}.${element(split(".",var.k8s_version),1)}-*"

  owners = ["496014204152"]
}

#########################################################
# Subnets
#########################################################

data "aws_nat_gateway" "ngws" {
  count = "${length(var.nat_gateway_ids)}"
  id    = "${element(var.nat_gateway_ids, count.index)}"
}

data "aws_subnet" "ngw_subnets" {
  count = "${length(var.nat_gateway_ids)}"
  id    = "${element(data.aws_nat_gateway.ngws.*.subnet_id, count.index)}"
}

# Private subnets to host the Kubernetes master nodes
data template_file "master-subnet-spec" {
  count    = "3"
  template = "${file("${path.module}/../templates/kops-cluster-subnet.tpl.yaml")}"

  vars {
    name   = "${element(formatlist("master-%s", data.aws_availability_zones.available.names),count.index)}"
    type   = "Private"
    zone   = "${element(data.aws_availability_zones.available.names, count.index)}"
    id     = ""
    cidr   = "${cidrsubnet(data.aws_vpc.vpc_for_k8s.cidr_block,8,var.master_net_number+count.index)}"
    egress = "${local.ngws_per_az[element(data.aws_availability_zones.available.names, count.index)]}"
  }
}

# Private subnets to host the Kubernetes worker nodes
data template_file "worker-subnet-spec" {
  count    = "3"
  template = "${file("${path.module}/../templates/kops-cluster-subnet.tpl.yaml")}"

  vars {
    name   = "${element(formatlist("worker-%s", data.aws_availability_zones.available.names), count.index)}"
    type   = "Private"
    zone   = "${element(data.aws_availability_zones.available.names, count.index)}"
    id     = ""
    cidr   = "${cidrsubnet(data.aws_vpc.vpc_for_k8s.cidr_block,8,var.worker_net_number+count.index)}"
    egress = "${local.ngws_per_az[element(data.aws_availability_zones.available.names, count.index)]}"
  }
}

# Utility subnets are public for ELB creation.
data template_file "utility-subnet-spec" {
  count    = "3"
  template = "${file("${path.module}/../templates/kops-cluster-subnet.tpl.yaml")}"

  vars {
    name   = "${element(formatlist("utility-%s", data.aws_availability_zones.available.names),count.index)}"
    type   = "Utility"
    zone   = "${element(data.aws_availability_zones.available.names, count.index)}"
    id     = ""
    cidr   = "${cidrsubnet(data.aws_vpc.vpc_for_k8s.cidr_block,8,var.utility_net_number+count.index)}"
    egress = ""
  }
}

#########################################################
# Instance Groups
#########################################################

locals {
  default_master_sg = "${length(var.extra_master_securitygroups) > 0 ? format("additionalSecurityGroups:\n %s",indent(1,join("\n",formatlist(" - %s",var.extra_master_securitygroups)))) : ""}"
  default_worker_sg = "${length(var.extra_worker_securitygroups) > 0 ? format("additionalSecurityGroups:\n %s",indent(1,join("\n",formatlist(" - %s",var.extra_worker_securitygroups)))) : ""}"
  spot_price        = "${var.spot_price != "" ? format("maxPrice: \"%s\"", var.spot_price) : ""}"
  ngws_per_az       = "${zipmap(data.aws_subnet.ngw_subnets.*.availability_zone, data.aws_nat_gateway.ngws.*.id)}"
}

data template_file "master-instancegroup-spec" {
  count    = 3
  template = "${file("${path.module}/../templates/kops-instancegroup-master.tpl.yaml")}"

  vars {
    name                        = "${element(formatlist("master-%s", data.aws_availability_zones.available.names),count.index)}"
    cluster-name                = "${var.name}"
    k8s_data_bucket             = "${var.k8s_data_bucket}"
    kubernetes_ami              = "${data.aws_ami.kubernetes_ami.name}"
    subnets                     = "${element(formatlist("  - master-%s", data.aws_availability_zones.available.names),count.index)}"
    instance_type               = "${var.master_instance_type}"
    teleport_bootstrap          = "${indent(6, module.teleport_bootstrap_script_master.teleport_bootstrap_script)}"
    teleport_config             = "${indent(6, module.teleport_bootstrap_script_master.teleport_config_cloudinit)}"
    teleport_service            = "${indent(6, module.teleport_bootstrap_script_master.teleport_service_cloudinit)}"
    extra_master_securitygroups = "${local.default_master_sg}"
  }
}

data template_file "worker-instancegroup-spec" {
  template = "${file("${path.module}/../templates/kops-instancegroup-worker.tpl.yaml")}"

  vars {
    name                        = "workers"
    cluster-name                = "${var.name}"
    kubernetes_ami              = "${data.aws_ami.kubernetes_ami.name}"
    subnets                     = "${join("\n", formatlist("  - worker-%s", data.aws_availability_zones.available.names))}"
    instance_type               = "${var.worker_instance_type}"
    min                         = "${length(data.aws_availability_zones.available.names)}"
    max                         = "${var.max_amount_workers}"
    teleport_bootstrap          = "${indent(6, module.teleport_bootstrap_script_worker.teleport_bootstrap_script)}"
    teleport_config             = "${indent(6, module.teleport_bootstrap_script_worker.teleport_config_cloudinit)}"
    teleport_service            = "${indent(6, module.teleport_bootstrap_script_worker.teleport_service_cloudinit)}"
    extra_worker_securitygroups = "${local.default_worker_sg}"
    spot_price                  = "${local.spot_price}"
  }
}

data template_file "helm-instancegroup-spec" {
  template = "${file("${path.module}/../templates/kops-instancegroup-helm.tpl.yaml")}"

  vars {
    name                        = "helm"
    cluster-name                = "${var.name}"
    kubernetes_ami              = "${data.aws_ami.kubernetes_ami.name}"
    subnets                     = "${join("\n", formatlist("  - worker-%s", data.aws_availability_zones.available.names))}"
    instance_type               = "t2.small"
    min                         = "1"
    max                         = "1"
    teleport_bootstrap          = "${indent(6, module.teleport_bootstrap_script_worker.teleport_bootstrap_script)}"
    teleport_config             = "${indent(6, module.teleport_bootstrap_script_worker.teleport_config_cloudinit)}"
    teleport_service            = "${indent(6, module.teleport_bootstrap_script_worker.teleport_service_cloudinit)}"
    extra_worker_securitygroups = "${local.default_worker_sg}"
  }
}

#########################################################
# Full Cluster
#########################################################

data template_file "cluster-etcd-member-spec" {
  template = "${file("${path.module}/../templates/kops-cluster-etcd-member.tpl.yaml")}"
  count    = "3"

  vars {
    name    = "${element(formatlist("master-%s", data.aws_availability_zones.available.names),count.index)}"
    ig-name = "${element(formatlist("master-%s", data.aws_availability_zones.available.names),count.index)}"
  }
}

data template_file "cluster-spec" {
  template = "${file("${path.module}/../templates/kops-cluster.tpl.yaml")}"

  vars {
    name                = "${var.name}"
    k8s_version         = "${var.k8s_version}"
    vpc_id              = "${data.aws_vpc.vpc_for_k8s.id}"
    vpc_cidr            = "${data.aws_vpc.vpc_for_k8s.cidr_block}"
    elb_type            = "${var.elb_type}"
    k8s_data_bucket     = "${var.k8s_data_bucket}"
    oidc_issuer_url     = "${var.oidc_issuer_url}"
    etcd_members_main   = "${join("\n",data.template_file.cluster-etcd-member-spec.*.rendered)}"
    etcd_members_events = "${join("\n",data.template_file.cluster-etcd-member-spec.*.rendered)}"
    etcd_version        = "${var.etcd_version}"
    master_subnets      = "${join("\n",data.template_file.master-subnet-spec.*.rendered)}"
    worker_subnets      = "${join("\n",data.template_file.worker-subnet-spec.*.rendered)}"
    utility_subnets     = "${join("\n",data.template_file.utility-subnet-spec.*.rendered)}"
    calico_logseverity  = "${var.calico_logseverity}"
  }
}

data template_file "kops_full_cluster-spec_file" {
  template = "${file("${path.module}/../templates/kops-full.tpl.yaml")}"

  vars {
    content_cluster      = "${data.template_file.cluster-spec.rendered}"
    content_master_group = "${join("\n",data.template_file.master-instancegroup-spec.*.rendered)}"
    content_worker_group = "${data.template_file.worker-instancegroup-spec.rendered}"
    content_helm_node    = "${var.helm_node == true ? data.template_file.helm-instancegroup-spec.rendered : ""}"
  }
}

resource "local_file" "kops_full_cluster-spec_file" {
  content  = "${data.template_file.kops_full_cluster-spec_file.rendered}"
  filename = "${path.cwd}/kops-cluster.yaml"
}

module "teleport_bootstrap_script_worker" {
  source      = "github.com/skyscrapers/terraform-teleport//teleport-bootstrap-script?ref=3.1.1"
  auth_server = "${var.teleport_server}"
  auth_token  = "${var.teleport_token}"
  function    = "worker"
  project     = "kubernetes"
  environment = "${var.environment}"
}

module "teleport_bootstrap_script_master" {
  source      = "github.com/skyscrapers/terraform-teleport//teleport-bootstrap-script?ref=3.1.1"
  auth_server = "${var.teleport_server}"
  auth_token  = "${var.teleport_token}"
  function    = "master"
  project     = "kubernetes"
  environment = "${var.environment}"
}

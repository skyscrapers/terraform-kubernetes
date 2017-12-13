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

# Private subnets to host the Kubernetes master nodes
data template_file "master-subnet-spec" {
  count    = "3"
  template = "${file("${path.module}/../templates/kops-cluster-subnet.tpl.yaml")}"

  vars {
    name = "${element(formatlist("master-%s", data.aws_availability_zones.available.names),count.index)}"
    type = "Private"
    zone = "${element(data.aws_availability_zones.available.names, count.index)}"
    id   = ""
    cidr = "${cidrsubnet(data.aws_vpc.vpc_for_k8s.cidr_block,8,var.master_net_number+count.index)}"
  }
}

# Private subnets to host the Kubernetes worker nodes
data template_file "worker-subnet-spec" {
  count    = "3"
  template = "${file("${path.module}/../templates/kops-cluster-subnet.tpl.yaml")}"

  vars {
    name = "${element(formatlist("worker-%s", data.aws_availability_zones.available.names), count.index)}"
    type = "Private"
    zone = "${element(data.aws_availability_zones.available.names, count.index)}"
    id   = ""
    cidr = "${cidrsubnet(data.aws_vpc.vpc_for_k8s.cidr_block,8,var.worker_net_number+count.index)}"
  }
}

# Utility subnets are public for ELB creation.
data template_file "utility-subnet-spec" {
  count    = "3"
  template = "${file("${path.module}/../templates/kops-cluster-subnet.tpl.yaml")}"

  vars {
    name = "${element(formatlist("utility-%s", data.aws_availability_zones.available.names),count.index)}"
    type = "Utility"
    zone = "${element(data.aws_availability_zones.available.names, count.index)}"
    id   = ""
    cidr = "${cidrsubnet(data.aws_vpc.vpc_for_k8s.cidr_block,8,var.utility_net_number+count.index)}"
  }
}

#########################################################
# Instance Groups
#########################################################

data template_file "master-instancegroup-spec" {
  count    = 3
  template = "${file("${path.module}/../templates/kops-instancegroup-master.tpl.yaml")}"

  vars {
    name               = "${element(formatlist("master-%s", data.aws_availability_zones.available.names),count.index)}"
    cluster-name       = "${var.name}"
    k8s_data_bucket    = "${var.k8s_data_bucket}"
    kubernetes_ami     = "${data.aws_ami.kubernetes_ami.name}"
    subnets            = "${element(formatlist("  - master-%s", data.aws_availability_zones.available.names),count.index)}"
    instance_type      = "${var.master_instance_type}"
    teleport_bootstrap = "${indent(6, module.teleport_bootstrap_script_master.teleport_bootstrap_script)}"
  }
}

data template_file "worker-instancegroup-spec" {
  template = "${file("${path.module}/../templates/kops-instancegroup-worker.tpl.yaml")}"

  vars {
    name               = "workers"
    cluster-name       = "${var.name}"
    kubernetes_ami     = "${data.aws_ami.kubernetes_ami.name}"
    subnets            = "${join("\n", formatlist("  - worker-%s", data.aws_availability_zones.available.names))}"
    instance_type      = "${var.worker_instance_type}"
    min                = "${length(data.aws_availability_zones.available.names)}"
    max                = "${var.max_amount_workers}"
    teleport_bootstrap = "${indent(6, module.teleport_bootstrap_script_worker.teleport_bootstrap_script)}"
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
  }
}

data template_file "kops_full_cluster-spec_file" {
  template = "${file("${path.module}/../templates/kops-full.tpl.yaml")}"

  vars {
    content_cluster      = "${data.template_file.cluster-spec.rendered}"
    content_master_group = "${join("\n",data.template_file.master-instancegroup-spec.*.rendered)}"
    content_worker_group = "${data.template_file.worker-instancegroup-spec.rendered}"
  }
}

resource "local_file" "kops_full_cluster-spec_file" {
  content  = "${data.template_file.kops_full_cluster-spec_file.rendered}"
  filename = "${path.cwd}/kops-cluster.yaml"
}

module "teleport_bootstrap_script_worker" {
  source      = "github.com/skyscrapers/terraform-teleport//teleport-bootstrap-script?ref=2.2.0"
  auth_server = "${var.teleport_server}"
  auth_token  = "${var.teleport_token}"
  function    = "worker"
  project     = "kubernetes"
  environment = "${var.environment}"
}

module "teleport_bootstrap_script_master" {
  source      = "github.com/skyscrapers/terraform-teleport//teleport-bootstrap-script?ref=2.2.0"
  auth_server = "${var.teleport_server}"
  auth_token  = "${var.teleport_token}"
  function    = "master"
  project     = "kubernetes"
  environment = "${var.environment}"
}

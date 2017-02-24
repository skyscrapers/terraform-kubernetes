terraform {
	required_version = "> 0.8.0"
}

# TODO list:
#  * Allow configuring the API ELB type: Public or Internal
#  * Use separate management and node subnets once the fix for this is released:
#      https://github.com/kubernetes/kops/issues/1980
#

data "aws_vpc" "vpc_for_k8s" {
  id = "${var.vpc_id}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

### NOTE: Do not change the layout of the template files or your will get unnecessary empty lines
###       in the generated output.

# Private subnets to host the Kubernetes master nodes
data template_file "master-subnet-spec" {
  count = "3"
  template = "${file("${path.module}/../templates/kops-cluster-subnet.tpl.yaml")}"

  vars {
    name = "management-${count.index}"
    type = "Private"
    zone = "${element(data.aws_availability_zones.available.names, count.index)}"
    id   = ""
    cidr = "${cidrsubnet(data.aws_vpc.vpc_for_k8s.cidr_block,8,var.master_net_number+count.index)}"
  }
}

# Private subnets to host the Kubernetes worker nodes
# Currently disabled due to https://github.com/kubernetes/kops/issues/1980
# data template_file "node-subnet-spec" {
#   count = "3"
#   template = "${file("${path.module}/../templates/kops-cluster-subnet.tpl.yaml")}"

#   vars {
#     name = "node-${count.index}"
#     type = "Private"
#     zone = "${element(data.aws_availability_zones.available.names, count.index)}"
#     id   = ""
#     cidr = "${cidrsubnet(data.aws_vpc.vpc_for_k8s.cidr_block,8,var.node_net_number+count.index)}"
#   }
# }

# Utility subnets are public for ELB creation.
data template_file "utility-subnet-spec" {
  count = "3"
  template = "${file("${path.module}/../templates/kops-cluster-subnet.tpl.yaml")}"

  vars {
    name = "utility-${count.index}"
    type = "Utility"
    zone = "${element(data.aws_availability_zones.available.names, count.index)}"
    id   = ""
    cidr = "${cidrsubnet(data.aws_vpc.vpc_for_k8s.cidr_block,8,var.utility_net_number+count.index)}"
  }
}

data template_file "cluster-spec" {
  template = "${file("${path.module}/../templates/kops-cluster.tpl.yaml")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    name = "${var.name}"
    k8s_version = "${var.k8s_version}"
    vpc_id = "${data.aws_vpc.vpc_for_k8s.id}"
    vpc_cidr = "${data.aws_vpc.vpc_for_k8s.cidr_block}"
    k8s_data_bucket = "${var.k8s_data_bucket}"
    master_subnets = "${join("\n",data.template_file.master-subnet-spec.*.rendered)}"
    #node_subnets = "${join("\n",data.template_file.node-subnet-spec.*.rendered)}"
    utility_subnets = "${join("\n",data.template_file.utility-subnet-spec.*.rendered)}"
  }
}

data template_file "master-instancegroup-spec" {
  count = 3
  template = "${file("${path.module}/../templates/kops-instancegroup-master.tpl.yaml")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    name = "${var.name}"
    index = "${count.index}"
  }
}

data template_file "nodes-instancegroup-spec" {
  template = "${file("${path.module}/../templates/kops-instancegroup-nodes.tpl.yaml")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    name = "${var.name}"
  }

}

resource "null_resource" "kops_full_cluster-spec_file" {

  provisioner "local-exec" {
    command = <<-EOC
      tee kops-cluster.yaml <<EOF
      ${data.template_file.cluster-spec.rendered}
      ${data.template_file.master-instancegroup-spec.0.rendered}
      ${data.template_file.master-instancegroup-spec.1.rendered}
      ${data.template_file.master-instancegroup-spec.2.rendered}
      ${data.template_file.nodes-instancegroup-spec.rendered}
      EOF
      EOC
  }

}
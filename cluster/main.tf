terraform {
	required_version = "> 0.8.0"
}

data template_file "cluster-spec" {
  template = "${file("${path.module}/../templates/kops-cluster.tpl.yaml")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    name = "${var.name}"
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
terraform {
  required_version = "> 0.9.4"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "external_dns_role" {
  name = "${var.name}_external_dns_role"
  path = "/kube2iam/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_nodes_iam_role_name}"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "external_dns_role_policy" {
  name = "${var.name}_external_dns_policy"
  role = "${aws_iam_role.external_dns_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "route53:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "kube2iam_assume_role_policy" {
  name = "${var.name}_kube2iam_assume_role_policy"
  role = "${var.cluster_nodes_iam_role_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/kube2iam/*"
    }
  ]
}
EOF
}

data "template_file" "helm_values" {
  template = "${file("${path.module}/../templates/helm-values.tpl.yaml")}"

  vars {
    nginx_controller_image_version = "${var.nginx_controller_image_version}"
    lego_email                     = "${var.lego_email}"
    lego_url                       = "${var.lego_url}"
    dex_github_client_id           = "${var.dex_github_client_id}"
    dex_github_client_secret       = "${var.dex_github_client_secret}"
    dex_github_org                 = "${var.dex_github_org}"
    kubesignin_client_secret       = "${var.kubesignin_client_secret}"
    kubesignin_domain_name         = "kubesignin.${var.name}"
    external_dns_role_arn          = "${aws_iam_role.external_dns_role.arn}"
  }
}

resource "null_resource" "helm_values_file" {
  triggers {
    content = "${data.template_file.helm_values.rendered}"
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee ${path.cwd}/helm_values.yaml <<EOF
      ${data.template_file.helm_values.rendered}
      EOF
      EOC
  }
}

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
    dex_image_tag                  = "${var.dex_image_tag}"
    dex_github_client_id           = "${var.dex_github_client_id}"
    dex_github_client_secret       = "${var.dex_github_client_secret}"
    dex_github_org                 = "${var.dex_github_org}"
    kubesignin_client_secret       = "${var.kubesignin_client_secret}"
    kubesignin_domain_name         = "kubesignin.${var.name}"
    external_dns_role_arn          = "${aws_iam_role.external_dns_role.arn}"
    opsgenie_api_key               = "${var.opsgenie_api_key}"
    bastion_cidr                   = "${var.bastion_cidr}"
    alertmanager_domain_name       = "alertmanager.${var.name}"
    alertmanager_volume_size       = "${var.alertmanager_volume_size}"
    prometheus_domain_name         = "prometheus.${var.name}"
    prometheus_volume_size         = "${var.prometheus_volume_size}"
    prometheus_retention           = "${var.prometheus_retention}"
    grafana_admin_user             = "${var.grafana_admin_user}"
    grafana_admin_password         = "${var.grafana_admin_password}"
    grafana_domain_name            = "grafana.${var.name}"
    grafana_volume_size            = "${var.grafana_volume_size}"
    environment                    = "${var.environment}"
    customer                       = "${var.customer}"
  }
}

resource "null_resource" "helm_values_file" {
  triggers {
    content = "${data.template_file.helm_values.rendered}"
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee ${path.cwd}/helm-values.yaml <<EOF
      ${data.template_file.helm_values.rendered}
      EOF
      EOC
  }
}

data "template_file" "helm_values_external_dns" {
  template = "${file("${path.module}/../templates/helm-values-external-dns.tpl.yaml")}"

  vars {
    external_dns_role_arn = "${aws_iam_role.external_dns_role.arn}"
    txt_owner_id = "${var.txt_owner_id}"
  }
}

resource "null_resource" "helm_values_external_dns_file" {
  triggers {
    content = "${data.template_file.helm_values_external_dns.rendered}"
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee ${path.cwd}/helm-values-external-dns.yaml <<EOF
      ${data.template_file.helm_values_external_dns.rendered}
      EOF
      EOC
  }
}

data "template_file" "helm_values_prometheus_operator" {
  template = "${file("${path.module}/../templates/helm-values-prometheus-operator.tpl.yaml")}"
}

resource "null_resource" "helm_values_prometheus_operator_file" {
  triggers {
    content = "${data.template_file.helm_values_prometheus_operator.rendered}"
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee ${path.cwd}/helm-values-prometheus-operator.yaml <<EOF
      ${data.template_file.helm_values_prometheus_operator.rendered}
      EOF
      EOC
  }
}

data "template_file" "helm_values_kube2iam" {
  template = "${file("${path.module}/../templates/helm-values-kube2iam.tpl.yaml")}"
}

resource "null_resource" "helm_values_kube2iam_file" {
  triggers {
    content = "${data.template_file.helm_values_kube2iam.rendered}"
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee ${path.cwd}/helm-values-kube2iam.yaml <<EOF
      ${data.template_file.helm_values_kube2iam.rendered}
      EOF
      EOC
  }
}

data "template_file" "helm_values_kube_lego" {
  template = "${file("${path.module}/../templates/helm-values-kube-lego.tpl.yaml")}"
  vars {
    lego_email = "${var.lego_email}"
    lego_url   = "${var.lego_url}"
  }
}

resource "null_resource" "helm_values_kube_lego_file" {
  triggers {
    content = "${data.template_file.helm_values_kube_lego.rendered}"
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee ${path.cwd}/helm-values-kube-lego.yaml <<EOF
      ${data.template_file.helm_values_kube_lego.rendered}
      EOF
      EOC
  }
}

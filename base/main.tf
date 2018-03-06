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

data "aws_region" "fluentd_region" {
  current = true
}

resource "aws_iam_role" "fluentd_role" {
  name = "${var.name}_fluentd_role"
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

resource "aws_iam_role_policy" "fluentd_role_policy" {
  name = "${var.name}_fluentd_policy"
  role = "${aws_iam_role.fluentd_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:*",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:logs:${local.fluentd_aws_region}:*:*",
        "arn:aws:s3:::*"
      ]
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

locals {
  default_opsgenie_heartbeat_name = "${upper(substr(var.customer,0,1))}${substr(var.customer,1,-1)} ${upper(substr(var.environment,0,1))}${substr(var.environment,1,-1)} Cluster Deadmanswitch"
  opsgenie_heartbeat_name         = "${var.opsgenie_heartbeat_name != "" ? var.opsgenie_heartbeat_name : local.default_opsgenie_heartbeat_name}"
  fluentd_aws_region              = "${var.fluentd_aws_region != "" ? var.fluentd_aws_region : data.aws_region.fluentd_region.name}"
  extra_grafana_datasoures        = "${indent(6,join("\n", data.template_file.helm_values_grafana_custom.*.rendered))}"
  extra_grafana_dashboards        = "${indent(6,var.extra_grafana_dashboards)}"
}

data "template_file" "helm_values" {
  template = "${file("${path.module}/../templates/helm-values.tpl.yaml")}"

  vars {
    nginx_controller_image_version = "${var.nginx_controller_image_version}"
    headers                        = "${indent(4, join("\n", data.template_file.kv_mapping.*.rendered))}"
    dex_image_tag                  = "${var.dex_image_tag}"
    dex_gh_connectors              = "${indent(6, join("\n", data.template_file.gh_connectors.*.rendered))}"
    dex_expiry_signingkeys         = "${var.dex_expiry_signingkeys}"
    dex_expiry_idtokens            = "${var.dex_expiry_idtokens}"
    kubesignin_client_secret       = "${var.kubesignin_client_secret}"
    kubesignin_domain_name         = "kubesignin.${var.name}"
    external_dns_role_arn          = "${aws_iam_role.external_dns_role.arn}"
    opsgenie_api_key               = "${var.opsgenie_api_key}"
    opsgenie_heartbeat_name        = "${local.opsgenie_heartbeat_name}"
    bastion_cidr                   = "188.166.18.33/32,176.58.117.229/32,${var.bastion_cidr}"
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
    slack_webhook_url              = "${var.slack_webhook_url}"
    extra_grafana_datasoures       = "${local.extra_grafana_datasoures}"
    extra_grafana_dashboards       = "${local.extra_grafana_dashboards}"
    extra_alertmanager_routes      = "${indent(8,var.extra_alertmanager_routes)}"
    extra_alertmanager_receivers   = "${indent(8,var.extra_alertmanager_receivers)}"
  }
}

data "template_file" "kv_mapping" {
  count    = "${length(var.headers)}"
  template = "$${key}: $${value}"

  vars {
    key   = "${element(keys(var.headers), count.index)}"
    value = "${element(values(var.headers), count.index)}"
  }
}

data "template_file" "gh_connectors" {
  count    = "${length(var.dex_gh_connectors)}"
  template = "${file("${path.module}/../templates/helm-values-dex-ghconnector.tpl.yaml")}"

  vars {
    name         = "${element(keys(var.dex_gh_connectors), count.index) }"
    clientId     = "${ lookup(var.dex_gh_connectors[element(keys(var.dex_gh_connectors), count.index)], "clientId")}"
    clientSecret = "${ lookup(var.dex_gh_connectors[element(keys(var.dex_gh_connectors), count.index)], "clientSecret")}"
    orgName      = "${ lookup(var.dex_gh_connectors[element(keys(var.dex_gh_connectors), count.index)], "orgName")}"
    teamName     = "${ lookup(var.dex_gh_connectors[element(keys(var.dex_gh_connectors), count.index)], "teamName")}"
  }
}

resource "local_file" "helm_values_file" {
  content  = "${data.template_file.helm_values.rendered}"
  filename = "${path.cwd}/helm-values.yaml"
}

data "template_file" "helm_values_external_dns" {
  template = "${file("${path.module}/../templates/helm-values-external-dns.tpl.yaml")}"

  vars {
    external_dns_role_arn = "${aws_iam_role.external_dns_role.arn}"
    txt_owner_id          = "${var.txt_owner_id}"
  }
}

resource "local_file" "helm_values_external_dns_file" {
  content  = "${data.template_file.helm_values_external_dns.rendered}"
  filename = "${path.cwd}/helm-values-external-dns.yaml"
}

data "template_file" "helm_values_prometheus_operator" {
  template = "${file("${path.module}/../templates/helm-values-prometheus-operator.tpl.yaml")}"
}

resource "local_file" "helm_values_prometheus_operator_file" {
  content  = "${data.template_file.helm_values_prometheus_operator.rendered}"
  filename = "${path.cwd}/helm-values-prometheus-operator.yaml"
}

data "template_file" "helm_values_kube2iam" {
  template = "${file("${path.module}/../templates/helm-values-kube2iam.tpl.yaml")}"
}

resource "local_file" "helm_values_kube2iam_file" {
  content  = "${data.template_file.helm_values_kube2iam.rendered}"
  filename = "${path.cwd}/helm-values-kube2iam.yaml"
}

data "template_file" "helm_values_kube_lego" {
  template = "${file("${path.module}/../templates/helm-values-kube-lego.tpl.yaml")}"

  vars {
    lego_email = "${var.lego_email}"
    lego_url   = "${var.lego_url}"
  }
}

resource "local_file" "helm_values_kube_lego_file" {
  content  = "${data.template_file.helm_values_kube_lego.rendered}"
  filename = "${path.cwd}/helm-values-kube-lego.yaml"
}

data "template_file" "helm_values_fluentd_cloudwatch" {
  template = "${file("${path.module}/../templates/helm-values-fluentd-cloudwatch.tpl.yaml")}"

  vars {
    fluentd_role_arn      = "${aws_iam_role.fluentd_role.arn}"
    fluentd_aws_region    = "${local.fluentd_aws_region}"
    fluentd_loggroupname  = "${var.fluentd_loggroupname}"
    fluentd_custom_config = "${indent(2, var.fluentd_custom_config)}"
  }
}

resource "local_file" "helm_values_fluentd_cloudwatch_file" {
  content  = "${data.template_file.helm_values_fluentd_cloudwatch.rendered}"
  filename = "${path.cwd}/helm-values-fluentd-cloudwatch.yaml"
}

data "template_file" "helm_values_kibana" {
  template = "${file("${path.module}/../templates/helm-values-kibana.tpl.yaml")}"

  vars {
    elasticsearch_url  = "${var.elasticsearch_url}"
    bastion_cidr       = "188.166.18.33/32,176.58.117.229/32,${var.bastion_cidr}"
    kibana_domain_name = "kibana.${var.name}"
    kibana_image_tag   = "${var.kibana_image_tag}"
  }
}

resource "local_file" "helm_values_kibana_file" {
  content  = "${data.template_file.helm_values_kibana.rendered}"
  filename = "${path.cwd}/helm-values-kibana.yaml"
}

resource "aws_cloudwatch_log_group" "fluentd" {
  name              = "${var.fluentd_loggroupname}"
  retention_in_days = "${var.fluentd_retention}"

  tags {
    Environment = "${var.environment}"
    customer    = "${var.customer}"
  }
}

data "template_file" "helm_values_grafana_custom" {
  count = "${length(var.extra_grafana_datasoures)}"

  template = "${file("${path.module}/../templates/helm-values-grafana-custom.tpl.yaml")}"

  vars {
    name = "${element(keys(var.extra_grafana_datasoures), count.index)}"
    url  = "${element(values(var.extra_grafana_datasoures), count.index)}"
  }
}

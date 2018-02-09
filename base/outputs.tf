output "external_dns_role_arn" {
  value = "${aws_iam_role.external_dns_role.arn}"
}

output "external_dns_role_name" {
  value = "${aws_iam_role.external_dns_role.name}"
}

output "fluentd_loggroupname" {
  value = "${var.fluentd_loggroupname}"
}

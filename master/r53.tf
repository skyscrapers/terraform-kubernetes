resource "aws_route53_zone" "cluster" {
  name   = "k8s-${var.project}-${var.environment}.internal"
  vpc_id = "${data.aws_subnet.subnet_info.vpc_id}"
}

resource "aws_route53_record" "masters" {
  zone_id = "${aws_route53_zone.cluster.zone_id}"
  name    = "${count.index +1}.master.${aws_route53_zone.cluster.name}"
  type    = "A"
  ttl     = "30"
  count   = "${var.amount_masters}"

  records = [
    "${element(module.masters.instance_private_ip, count.index)}",
  ]
}

resource "aws_route53_record" "api" {
  zone_id = "${aws_route53_zone.cluster.zone_id}"
  name    = "api.${aws_route53_zone.cluster.name}"
  type    = "A"

  alias {
    name                   = "${module.master_elb.elb_dns_name}"
    zone_id                = "${module.master_elb.elb_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "etcd3_server_srv" {
  zone_id = "${aws_route53_zone.cluster.zone_id}"
  name    = "_etcd-server._tcp.etcd3.${aws_route53_zone.cluster.name}"
  type    = "SRV"
  ttl     = "30"

  records = [
    "${formatlist("0 0 2390 %s", aws_route53_record.masters.*.fqdn)}",
  ]
}

resource "aws_route53_record" "etcd3_client_srv" {
  zone_id = "${aws_route53_zone.cluster.zone_id}"
  name    = "_etcd-client._tcp.etcd3.${aws_route53_zone.cluster.name}"
  type    = "SRV"
  ttl     = "30"

  records = [
    "${formatlist("0 0 2389 %s", aws_route53_record.masters.*.fqdn)}",
  ]
}

resource "aws_route53_record" "etcd2_server_ssl_srv" {
  zone_id = "${aws_route53_zone.cluster.zone_id}"
  name    = "_etcd-server._tcp.etcd2.${aws_route53_zone.cluster.name}"
  type    = "SRV"
  ttl     = "30"

  records = [
    "${formatlist("0 0 2380 %s", aws_route53_record.masters.*.fqdn)}",
  ]
}

resource "aws_route53_record" "etcd2_client_ssl_srv" {
  zone_id = "${aws_route53_zone.cluster.zone_id}"
  name    = "_etcd-client._tcp.etcd2.${aws_route53_zone.cluster.name}"
  type    = "SRV"
  ttl     = "30"

  records = [
    "${formatlist("0 0 2379 %s", aws_route53_record.masters.*.fqdn)}",
  ]
}
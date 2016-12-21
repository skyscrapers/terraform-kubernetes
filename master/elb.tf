module "master_elb" {
  source            = "github.com/skyscrapers/terraform-loadbalancers//elb_no_ssl_no_s3logs?ref=be1e9c0f5b030a8a46609954b701a0882551e93d"
  name              = "k8s-master"
  subnets           = ["${var.subnets}"]
  project           = "${var.project}"
  environment       = "${var.environment}"
  instance_port     = 6443
  instance_protocol = "tcp"
  lb_port           = 6443
  lb_protocol       = "tcp"
  health_target     = "HTTP:8080/healthz"
  internal          = true
  backend_sg        = ["${aws_security_group.masters.id}"]
  backend_sg_count  = 1
}

resource "aws_elb_attachment" "master-attach" {
  elb      = "${module.master_elb.elb_id}"
  count    = "${var.amount_masters}"
  instance = "${element(module.masters.instance_ids, count.index)}"
}

resource "aws_security_group_rule" "allow_backend_healthcheck" {
  security_group_id = "${module.master_elb.sg_id}"
  type = "egress"
  from_port = 8080
  to_port = 8080
  protocol = "TCP"
  source_security_group_id = "${aws_security_group.masters.id}"
}

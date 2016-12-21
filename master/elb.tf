module "master_elb" {
  source            = "github.com/skyscrapers/terraform-loadbalancers//elb_no_ssl_no_s3logs?ref=d1be8a322a1fa5e757ffa6c011aec66b000d10cd"
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
}

resource "aws_elb_attachment" "master-attach" {
  elb      = "${module.master_elb.elb_id}"
  count    = "${var.amount_masters}"
  instance = "${element(module.masters.instance_ids, count.index)}"
}

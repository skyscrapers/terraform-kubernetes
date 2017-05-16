resource "aws_security_group" "masters" {
  name   = "k8s-master-${var.project}-${var.environment}"
  vpc_id = "${data.aws_subnet.subnet_info.vpc_id}"
}

data "aws_subnet" "subnet_info" {
  id = "${var.subnets[0]}"
}

resource "aws_security_group_rule" "incoming_elb_api" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = "${module.master_elb.sg_id}"

resource "aws_security_group_rule" "incoming_etcd3_self" {
  type      = "ingress"
  from_port = 2379
  to_port   = 2380
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.masters.id}"
}

resource "aws_security_group_rule" "incoming_etcd3_self" {
  type      = "ingress"
  from_port = 2389
  to_port   = 2390
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.masters.id}"
}

resource "aws_security_group_rule" "incoming_ssh_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${var.bastion_sg}"

  security_group_id = "${aws_security_group.masters.id}"
}

resource "aws_security_group_rule" "incoming_icmp" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.masters.id}"
}

resource "aws_security_group_rule" "allow_all_outgoing" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.masters.id}"
}

resource "aws_security_group_rule" "allow_k8s_admin_to_masters" {
  type        = "egress"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  security_group_id = "${var.bastion_sg}"
  source_security_group_id = "${module.master_elb.sg_id}"
}


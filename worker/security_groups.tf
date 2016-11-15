resource "aws_security_group" "workers" {
  name   = "k8s-worker-${var.project}-${var.environment}"
  vpc_id = "${data.aws_subnet.subnet_info.vpc_id}"
}

data "aws_subnet" "subnet_info" {
  id = "${var.subnets[0]}"
}

resource "aws_security_group_rule" "incoming_master_healthcheck" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = "${var.master_sg}"

  security_group_id = "${aws_security_group.workers.id}"
}

resource "aws_security_group_rule" "incoming_svc" {
  type        = "ingress"
  from_port   = 30000
  to_port     = 32767
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] #probably need to review this later

  security_group_id = "${aws_security_group.workers.id}"
}

resource "aws_security_group_rule" "incoming_self_master" {
  type                     = "ingress"          # needs to be reviewed later
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = "${var.master_sg}"

  security_group_id = "${aws_security_group.workers.id}"
}

resource "aws_security_group_rule" "incoming_self" {
  type      = "ingress" # needs to be reviewed later
  from_port = 0
  to_port   = 65535
  protocol  = "tcp"
  self      = true

  security_group_id = "${aws_security_group.workers.id}"
}

resource "aws_security_group_rule" "incoming_ssh_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${var.bastion_sg}"

  security_group_id = "${aws_security_group.workers.id}"
}

resource "aws_security_group_rule" "incoming_icmp" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.workers.id}"
}

resource "aws_security_group_rule" "allow_all_outgoing" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.workers.id}"
}

resource "aws_security_group_rule" "allow_etcdproxy_to_master" {
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2380
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.workers.id}"

  security_group_id = "${var.master_sg}"
}

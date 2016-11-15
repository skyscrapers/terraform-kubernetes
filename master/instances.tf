module "masters" {
  source         = "github.com/skyscrapers/terraform-instances//instance?ref=0988c9baab71ca9a20b851ea1c37ef6939fe5186"
  project        = "${var.project}"
  environment    = "${var.environment}"
  name           = "k8s-master-"
  sgs            = ["${aws_security_group.masters.id}"]
  subnets        = ["${var.subnets}"]
  key_name       = "${var.key_name}"
  ami            = "${var.ami}"
  instance_type  = "${var.instance_type}"
  instance_count = "${var.amount_masters}"
  user_data      = ["${data.template_file.user_data.*.rendered}"]
  public_ip      = false
}

data "template_file" "user_data" {
  template = "${file("${path.module}/../templates/master-cloud-config.tpl")}"
  count    = "${var.amount_masters}"

  vars {
    master_num  = "${count.index +1}"
    project     = "${var.project}"
    environment = "${var.environment}"
    endpoints   = "${join(",", formatlist("https://%s.master.k8s-%s-%s.internal:2379", var.endpoints_map[var.amount_masters], var.project, var.environment))}"
  }
}

resource "aws_volume_attachment" "ebs_att_master" {
  device_name = "/dev/sdh"
  count       = "${var.amount_masters}"
  volume_id   = "${element(aws_ebs_volume.masters.*.id, count.index)}"
  instance_id = "${element(module.masters.instance_ids, count.index)}"

  lifecycle {
    ignore_changes = ["instance"]
  }
}

resource "aws_ebs_volume" "masters" {
  count             = "${var.amount_masters}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
  size              = 20
  type              = "gp2"
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "masters" {
  source         = "github.com/skyscrapers/terraform-instances//instance?ref=16744c4d6e1ca7d346d6530ce8c83229b91c0390"
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
  template = "${file("${path.module}/../templates/master/master-cloud-config.tpl.yaml")}"
  count    = "${var.amount_masters}"

  vars {
    master_num  = "${count.index +1}"
    project     = "${var.project}"
    environment = "${var.environment}"
    k8s_version = "v1.4.6_coreos.0"
    endpoints   = "${join(",", formatlist("https://%s.master.k8s-%s-%s.internal:2379", var.endpoints_map[var.amount_masters], var.project, var.environment))}"
    content_ca_pem = "${base64encode(file("${path.cwd}/pki/kubernetes/ca/ca.pem"))}"
    content_client_pem = "${base64encode(file("${path.cwd}/pki/etcd2/etcd2-client-client.pem"))}"
    content_client_key_pem = "${base64encode(file("${path.cwd}/pki/etcd2/etcd2-client-client-key.pem"))}"
    content_peer_pem = "${base64encode(file("${path.cwd}/pki/etcd2/etcd2-peer-client.pem"))}"
    content_peer_key_pem = "${base64encode(file("${path.cwd}/pki/etcd2/etcd2-peer-client-key.pem"))}"
    content_server_pem = "${base64encode(file("${path.cwd}/pki/etcd2/etcd2-server-server.pem"))}"
    content_server_key_pem = "${base64encode(file("${path.cwd}/pki/etcd2/etcd2-server-server-key.pem"))}"
  }
}

resource "aws_volume_attachment" "ebs_att_master" {
  device_name = "/dev/sdh"
  count       = "${var.amount_masters}"
  volume_id   = "${element(aws_ebs_volume.masters.*.id, count.index)}"
  instance_id = "${element(module.masters.instance_ids, count.index)}"

  skip_destroy = true
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

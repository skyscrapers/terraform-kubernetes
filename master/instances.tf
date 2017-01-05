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

data "aws_s3_bucket_object" "ca_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/kubernetes/ca/ca.pem"
}

data "aws_s3_bucket_object" "etcd2_client_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/etcd2/etcd2-client-client.pem"
}

data "aws_s3_bucket_object" "etcd2_client_key_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/etcd2/etcd2-client-client-key.pem"
}

data "aws_s3_bucket_object" "etcd2_peer_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/etcd2/etcd2-peer-client.pem"
}

data "aws_s3_bucket_object" "etcd2_peer_key_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/etcd2/etcd2-peer-client-key.pem"
}

data "aws_s3_bucket_object" "etcd2_server_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/etcd2/etcd2-server-server.pem"
}

data "aws_s3_bucket_object" "etcd2_server_key_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/etcd2/etcd2-server-server-key.pem"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/../templates/master/master-cloud-config.tpl.yaml")}"
  count    = "${var.amount_masters}"

  vars {
    master_num  = "${count.index +1}"
    project     = "${var.project}"
    environment = "${var.environment}"
    k8s_version = "${var.k8s_version}"
    cluster_dns = "${cidrhost(data.aws_vpc.vpc_info.cidr_block, 2) }"
    endpoints   = "${join(",", formatlist("https://%s.master.k8s-%s-%s.internal:2379", var.endpoints_map[var.amount_masters], var.project, var.environment))}"
    content_ca_pem = "${base64encode("${data.aws_s3_bucket_object.ca_pem.body}")}"
    content_client_pem = "${base64encode("${data.aws_s3_bucket_object.etcd2_client_pem.body}")}"
    content_client_key_pem = "${base64encode("${data.aws_s3_bucket_object.etcd2_client_key_pem.body}")}"
    content_peer_pem = "${base64encode("${data.aws_s3_bucket_object.etcd2_peer_pem.body}")}"
    content_peer_key_pem = "${base64encode("${data.aws_s3_bucket_object.etcd2_peer_key_pem.body}")}"
    content_server_pem = "${base64encode("${data.aws_s3_bucket_object.etcd2_server_pem.body}")}"
    content_server_key_pem = "${base64encode("${data.aws_s3_bucket_object.etcd2_server_key_pem.body}")}"
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

data "aws_vpc" "vpc_info" {
 id = "${data.aws_subnet.subnet_info.vpc_id}"
}

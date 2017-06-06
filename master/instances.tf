data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "vpc_info" {
  id = "${data.aws_subnet.subnet_info.vpc_id}"
}

module "masters" {
  source         = "github.com/skyscrapers/terraform-bluegreen//blue-green?ref=1.0.0"
  project        = "${var.project}"
  environment    = "${var.environment}"
  name           = "k8s-master"
  security_groups = ["${aws_security_group.masters.id}"]
  subnets        = ["${var.subnets}"]
  key_name       = "${var.key_name}"
  blue_ami       = "${var.blue_ami}"
  blue_min_size  = 0
  blue_desired_capacity = "${var.amount_blue_masters}"
  blue_max_size     = "${var.amount_blue_masters}"
  green_ami      = "${var.green_ami}"
  green_min_size  = 0
  green_desired_capacity = "${var.amount_green_masters}"
  green_max_size     = "${var.amount_green_masters}"
  instance_type  = "${var.instance_type}"
//  user_data      = ["${data.template_file.user_data.*.rendered}"]
  associate_public_ip_address = true # TODO Change to false after module development & testing.
}

data "aws_s3_bucket_object" "ca_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/kubernetes/ca/ca.pem"
}

data "aws_s3_bucket_object" "etcd3_client_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/etcd3/etcd3-client-client.pem"
}

data "aws_s3_bucket_object" "etcd3_client_key_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/etcd3/etcd3-client-client-key.pem"
}

data "aws_s3_bucket_object" "etcd3_peer_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/etcd3/etcd3-peer-client.pem"
}

data "aws_s3_bucket_object" "etcd3_peer_key_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/etcd3/etcd3-peer-client-key.pem"
}

data "aws_s3_bucket_object" "etcd3_server_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/etcd3/etcd3-server-server.pem"
}

data "aws_s3_bucket_object" "etcd3_server_key_pem" {
  bucket = "${var.k8s_data_bucket}"
  key = "/pki/etcd3/etcd3-server-server-key.pem"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/../templates/master/master-cloud-config.tpl.yaml")}"

  vars {
    master_num  = "${count.index +1}"
    project     = "${var.project}"
    environment = "${var.environment}"
    k8s_version = "${var.k8s_blue_version}"
    cluster_dns = "${cidrhost(data.aws_vpc.vpc_info.cidr_block, 2) }"
    endpoints   = "http://10.13.10.101:2379"
    content_ca_pem = "${base64encode("${data.aws_s3_bucket_object.ca_pem.body}")}"
    content_client_pem = "${base64encode("${data.aws_s3_bucket_object.etcd3_client_pem.body}")}"
    content_client_key_pem = "${base64encode("${data.aws_s3_bucket_object.etcd3_client_key_pem.body}")}"
    content_peer_pem = "${base64encode("${data.aws_s3_bucket_object.etcd3_peer_pem.body}")}"
    content_peer_key_pem = "${base64encode("${data.aws_s3_bucket_object.etcd3_peer_key_pem.body}")}"
    content_server_pem = "${base64encode("${data.aws_s3_bucket_object.etcd3_server_pem.body}")}"
    content_server_key_pem = "${base64encode("${data.aws_s3_bucket_object.etcd3_server_key_pem.body}")}"
  }
}

//resource "aws_volume_attachment" "ebs_att_master" {
//  device_name = "/dev/sdh"
//  count       = "${var.amount_masters}"
//  volume_id   = "${element(aws_ebs_volume.masters.*.id, count.index)}"
//  instance_id = "${element(module.masters.instance_ids, count.index)}"
//
//  skip_destroy = true
//}
//
//resource "aws_ebs_volume" "masters" {
//  count             = "${var.amount_masters}"
//  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
//  size              = 20
//  type              = "gp2"
//}

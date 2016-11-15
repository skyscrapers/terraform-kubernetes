variable "worker_ami" {}

variable "master_ami" {}

variable "key_name" {}

variable "worker_instance_type" {
  default = "t2.medium"
}

variable "master_instance_type" {
  default = "t2.medium"
}

variable "bastion_sg" {}

variable "worker_subnets" {
  type = "list"
}

variable "master_subnets" {
  type = "list"
}

variable "project" {}

variable "environment" {}

variable "max_amount_workers" {}

variable "amount_masters" {}

variable "worker_user_data" {}

module "workers" {
  source             = "../worker"
  ami                = "${var.worker_ami}"
  instance_type      = "${var.worker_instance_type}"
  key_name           = "${var.key_name}"
  master_sg          = "${module.masters.master_sg}"
  bastion_sg         = "${var.bastion_sg}"
  subnets            = ["${var.worker_subnets}"]
  project            = "${var.project}"
  environment        = "${var.environment}"
  max_amount_workers = "${var.max_amount_workers}"
  user_data          = "${var.worker_user_data}"
}

module "masters" {
  source         = "../master"
  ami            = "${var.master_ami}"
  instance_type  = "${var.master_instance_type}"
  key_name       = "${var.key_name}"
  bastion_sg     = "${var.bastion_sg}"
  subnets        = ["${var.master_subnets}"]
  project        = "${var.project}"
  environment    = "${var.environment}"
  amount_masters = "${var.amount_masters}"
}

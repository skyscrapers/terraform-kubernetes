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
  k8s_data_bucket    = "${var.k8s_data_bucket}"
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
  k8s_data_bucket = "${var.k8s_data_bucket}"
}

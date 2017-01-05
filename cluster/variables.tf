variable "worker_ami" {}

variable "master_ami" {}

variable "key_name" {}

variable "worker_instance_type" {
  default = "t2.medium"
}

variable "k8s_data_bucket" {}

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

variable "cluster_cidr" {}

variable "k8s_version" {}

variable "service_ip_range" {}

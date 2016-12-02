variable "project" {}

variable "environment" {}

variable "master_sg" {}

variable "subnets" {
  type = "list"
}

variable "max_amount_workers" {}

variable "ami" {}

variable "key_name" {}
variable "bastion_sg" {}

variable "instance_type" {}

variable "k8s_data_bucket" {}

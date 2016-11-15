variable "project" {}

variable "environment" {}

variable "master_sg" {}

variable "subnets" {
  type = "list"
}

variable "max_amount_workers" {}

variable "ami" {}

variable "key_name" {}

variable "user_data" {}

variable "bastion_sg" {}

variable "instance_type" {}

variable "ami" {}

variable "instance_type" {}

variable "key_name" {}

variable "master_security_groups" {
  default = ""
}

variable "k8s_data_bucket" {}

variable "bastion_sg" {}

variable "subnets" {
  type = "list"
}

variable "project" {}

variable "environment" {}

variable "amount_masters" {}

variable "endpoints_map" {
  type = "map"

  default = {
    "1" = ["1"]
    "3" = ["1", "2", "3"]
    "5" = ["1", "2", "3", "4", "5"]
    "7" = ["1", "2", "3", "4", "5", "6", "7"]
    "9" = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
  }
}

variable "cluster_cidr" {}

variable "k8s_version" {}

variable "service_ip_range" {}

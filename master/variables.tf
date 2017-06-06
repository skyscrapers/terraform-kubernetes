variable "blue_ami" {}
variable "green_ami" {}

variable "instance_type" {
  default = "t2.small"
}

variable "key_name" {}

//variable "master_security_groups" {
//  default = ""
//}

variable "k8s_data_bucket" {}

//variable "bastion_sg" {}

variable "subnets" {
  type = "list"
}

variable "project" {}

variable "environment" {}

variable "amount_blue_masters" {}
variable "amount_green_masters" {}

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

//variable "cluster_cidr" {}

variable "k8s_blue_version" {}
variable "k8s_green_version" {}

//variable "service_ip_range" {}

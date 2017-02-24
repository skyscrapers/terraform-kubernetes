# variable "worker_ami" {}

# variable "master_ami" {}

variable "name" {
	description = "Kubernetes Cluster Name"
}

variable "key_name" {}

# variable "worker_instance_type" {
#   default = "t2.medium"
# }

variable "k8s_data_bucket" {
	description = "S3 bucket to store the kops cluster description & state"
}

# variable "master_instance_type" {
#   default = "t2.medium"
# }

# variable "bastion_sg" {}

# variable "worker_subnets" {
#   type = "list"
# }

variable "master_net_number" {
	description = "The network number to start with for master subnet cidr calculation"
}

# Currently disabled due to https://github.com/kubernetes/kops/issues/1980
# variable "node_net_number" {
# 	description = "The network number to start with for node subnet cidr calculation"
# }

variable "utility_net_number" {
	description = "The network number to start with for utility subnet cidr calculation"
}

variable "project" {}

variable "environment" {}

variable "vpc_id" {
	description = "Deploy the Kubernetes cluster in this VPC"
}

# variable "max_amount_workers" {}

# variable "amount_masters" {}

variable "k8s_version" {
	description = "Kubernetes Version to deploy"
}

# variable "service_ip_range" {}

variable "name" {
	description = "Kubernetes Cluster Name"
}

variable "k8s_data_bucket" {
	description = "S3 bucket to store the kops cluster description & state"
}

variable "vpc_id" {
	description = "Deploy the Kubernetes cluster in this VPC"
}

variable "elb_type" {
	description = "Whether to use an Internal or Public ELB in front of the master nodes"
	default = "Public"
}

variable "worker_instance_type" {
  default = "t2.medium"
}

variable "max_amount_workers" {
	description = "Maximum amount of workers, minimum will be the amount of AZ"
}

variable "worker_net_number" {
	description = "The network number to start with for worker subnet cidr calculation"
}

variable "master_instance_type" {
  default = "t2.medium"
}

variable "master_net_number" {
	description = "The network number to start with for master subnet cidr calculation"
}

variable "utility_net_number" {
	description = "The network number to start with for utility subnet cidr calculation"
}

variable "k8s_version" {
	description = "Kubernetes Version to deploy"
}

variable "oidc_issuer_url" {
	description = "URL for the OIDC issuer (https://kubernetes.io/docs/admin/authentication/#openid-connect-tokens)"
}

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
  default     = "Public"
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

variable "etcd_version" {
  description = "Which version of etcd do you want?"
  default     = ""
}

variable "teleport_token" {
  description = "Teleport auth token that this node will present to the auth server"
}

variable "teleport_server" {
  description = "Teleport auth server that this node will connect to, including the port number"
}

variable "environment" {
  description = "Environment where this node belongs to, will be the third part of the node name. Defaults to ''"
  default     = ""
}

variable "helm_node" {
  description = "Do we want a seperate node to deploy helm"
  default     = false
}

variable "extra_worker_securitygroups" {
  description = "List of extra securitygroups that you want to attach to the worker nodes"
  type        = "list"
  default     = []
}

variable "extra_master_securitygroups" {
  description = "List of extra securitygroups that you want to attach to the master nodes"
  type        = "list"
  default     = []
}

variable "spot_price" {
  description = "Spot price you want to pay for your worker instances. By default this is empty and we will use on-demand instances"
  default     = ""
}

variable "calico_logseverity" {
  description = "Sets the logSeverityScreen setting for the Calico CNI. Defaults to 'warning'"
  default     = "warning"
}

variable "nat_gateway_ids" {
  description = "List of NAT gateway ids to associate to the route tables created by kops. There must be one NAT gateway for each availability zone in the region."
  type        = "list"
}

variable "bastion_cidr" {
  description = "CIDR of the bastion host. This will be used to allow SSH access to kubernetes nodes."
}

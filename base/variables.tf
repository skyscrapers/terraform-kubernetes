variable "name" {
  description = "Kubernetes Cluster Name"
}

variable "cluster_nodes_iam_role_name" {
  description = "IAM role name for the k8s cluster worker nodes"
}

variable "nginx_controller_image_version" {
  description = ""
  default = "0.9.0-beta.7"
}

variable "lego_email" {
  description = ""
}

variable "lego_url" {
  description = ""
  default = "https://acme-v01.api.letsencrypt.org/directory"
}

variable "dex_github_client_id" {
  description = ""
}

variable "dex_github_client_secret" {
  description = ""
}

variable "dex_github_org" {
  description = ""
}

variable "kubesignin_client_secret" {
  description = ""
}

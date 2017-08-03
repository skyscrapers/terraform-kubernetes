variable "name" {
  description = "Kubernetes Cluster Name"
}

variable "cluster_nodes_iam_role_name" {
  description = "IAM role name for the k8s cluster worker nodes"
}

variable "nginx_controller_image_version" {
  description = ""
  default     = "0.9.0-beta.7"
}

variable "lego_email" {
  description = ""
}

variable "lego_url" {
  description = ""
  default     = "https://acme-v01.api.letsencrypt.org/directory"
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

variable "opsgenie_api_key" {
  description = "Opsgenie API key from your prometheus integration"
}

variable "bastion_cidr" {
  description = "Bastion IP of your kubernetes cluster"
}

variable "alertmanager_volume_size" {
  description = "Persistent volume size for the AlertManager"
  default     = "20Gi"
}

variable "prometheus_volume_size" {
  description = "Persistent volume size for Prometheus"
  default     = "100Gi"
}

variable "prometheus_retention" {
  description = "Data retention period for Prometheus"
  default     = "336h"
}

variable "grafana_admin_user" {
  description = "Grafana admin user name"
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin user password"
  default     = "admin"
}

variable "grafana_volume_size" {
  description = "Persistent volume size for Grafana"
  default     = "10Gi"
}

variable "environment" {
  description = "Environment of the cluster"
}

variable "customer" {
  description = "Customer name"
}

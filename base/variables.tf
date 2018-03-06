variable "name" {
  description = "Kubernetes Cluster Name"
}

variable "cluster_nodes_iam_role_name" {
  description = "IAM role name for the k8s cluster worker nodes"
}

variable "nginx_controller_image_version" {
  description = ""
  default     = "0.11.0"
}

variable "lego_email" {
  description = ""
}

variable "lego_url" {
  description = ""
  default     = "https://acme-v01.api.letsencrypt.org/directory"
}

variable "dex_image_tag" {
  default = "v2.4.1"
}

variable "dex_expiry_signingkeys" {
  description = "The duration of time after which the Dex SigningKeys will be rotated (default: 6h)."
  default     = "6h"
}

variable "dex_expiry_idtokens" {
  description = "The duration of time for which the Dex IdTokens will be valid (default: 1h). This value shouldn't be longer than dex_expiry_signingkeys."
  default     = "1h"
}

variable "kubesignin_client_secret" {
  description = ""
}

variable "opsgenie_api_key" {
  description = "Opsgenie API key from your prometheus integration"
}

variable "opsgenie_heartbeat_name" {
  description = "Opsgenie heartbeat name"
  default     = ""
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

variable "txt_owner_id" {
  default = "external-dns-controller"
}

variable "proxy_header_configmap" {
  default = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook API url as found in your webhook configuration"
}

variable "headers" {
  default = {
    "X-Request-Start" = "t=$${msec}"
  }
}

variable "dex_gh_connectors" {
  type = "map"
}

variable "fluentd_loggroupname" {
  description = "Cloudwatch loggroupname for fluentd-cloudwatch"
  default     = "kubernetes"
}

variable "fluentd_aws_region" {
  description = "AWS region where we want to store our logs we shipped from Fluentd to Cloudwatch"
  default     = ""
}

variable "fluentd_custom_config" {
  description = "Add custom fluentd config"
  default     = ""
}

variable "fluentd_retention" {
  description = "How long do we want to keep the Fluentd logs in Cloudwatch logs"
  default     = "30"
}

variable "elasticsearch_url" {
  description = "The URL for elasticsearch. If not filled in, you will not be able to deploy Kibana."
  default     = ""
}

variable "kibana_image_tag" {
  description = "Image tag of the kibana image"
  default     = "6.0.0"
}

variable "extra_grafana_datasoures" {
  description = "Extra Grafana datasource urls we want to add. Form is a map with name as key and url as value"
  type        = "map"
  default     = {}
}

variable "extra_grafana_dashboards" {
  description = "Extra Grafana dashboards we want to add."
  default     = ""
}

variable "extra_alertmanager_routes" {
  description = "Extra alertmanager routes."
  default     = ""
}

variable "extra_alertmanager_receivers" {
  description = "Extra alertmanager receivers."
  default     = ""
}

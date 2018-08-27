data "http" "k8s-worker-resource-requests-dashboard" {
  url = "https://raw.githubusercontent.com/skyscrapers/grafana-dashboards/master/k8s-workers-resource-requests-dashboard.yaml"
}

data "http" "k8s-calico-dashboard" {
  url = "https://raw.githubusercontent.com/skyscrapers/grafana-dashboards/master/k8s-calico-dashboard.yaml"
}

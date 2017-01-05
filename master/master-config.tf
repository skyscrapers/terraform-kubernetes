### KUBE-APISERVER

data "template_file" "kube_apiserver" {
  template = "${file("${path.module}/../templates/master/kube-apiserver.tpl.yaml")}"
  count    = "${var.amount_masters}"

  vars {
    service_ip_range = "${var.service_ip_range}"
    k8s_version      = "${var.k8s_version}"
    etcd_servers     = "${join(",", formatlist("http://%s.master.k8s-%s-%s.internal:2389", var.endpoints_map[var.amount_masters], var.project, var.environment))}"
    private_ip       = "${element(module.masters.instance_private_ip, count.index)}"
  }
}

resource "aws_s3_bucket_object" "kube_apiserver" {
  key     = "manifests/master/${count.index + 1}.master/kube-apiserver.yaml"
  bucket  = "${var.k8s_data_bucket}"
  content = "${element(data.template_file.kube_apiserver.*.rendered, count.index)}"
  count   = "${var.amount_masters}"
}

### KUBE-CONTROLLER-MANAGER

data "template_file" "kube_controller_manager" {
  template = "${file("${path.module}/../templates/master/kube-controller-manager.tpl.yaml")}"
  count    = "${var.amount_masters}"

  vars {
    service_ip_range = "${var.service_ip_range}"
    k8s_version      = "${var.k8s_version}"

    #etcd_servers     = "${join(",", formatlist("http://%s.master.k8s-%s-%s.internal:2389", var.endpoints_map[var.amount_masters], var.project, var.environment))}"
    #private_ip       = "${element(module.masters.instance_private_ip, count.index)}"
    cluster_cidr = "${var.cluster_cidr}"
  }
}

resource "aws_s3_bucket_object" "kube_controller_manager" {
  key     = "manifests/master/${count.index + 1}.master/kube-controller-manager.yaml"
  bucket  = "${var.k8s_data_bucket}"
  content = "${element(data.template_file.kube_controller_manager.*.rendered, count.index)}"
  count   = "${var.amount_masters}"
}

### KUBE-PROXY

data "template_file" "kube_proxy" {
  template = "${file("${path.module}/../templates/master/kube-proxy.tpl.yaml")}"
  count    = "${var.amount_masters}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"

    #service_ip_range = "10.0.0.0/16"
    k8s_version = "${var.k8s_version}"

    #etcd_servers     = "${join(",", formatlist("http://%s.master.k8s-%s-%s.internal:2389", var.endpoints_map[var.amount_masters], var.project, var.environment))}"

    #private_ip       = "${element(module.masters.instance_private_ip, count.index)}"
  }
}

resource "aws_s3_bucket_object" "kube_proxy" {
  key     = "manifests/master/${count.index + 1}.master/kube-proxy.yaml"
  bucket  = "${var.k8s_data_bucket}"
  content = "${element(data.template_file.kube_proxy.*.rendered, count.index)}"
  count   = "${var.amount_masters}"
}

### KUBE-SCHEDULER

data "template_file" "kube_scheduler" {
  template = "${file("${path.module}/../templates/master/kube-scheduler.tpl.yaml")}"
  count    = "${var.amount_masters}"

  vars {
    #service_ip_range = "10.0.0.0/16"
    k8s_version = "${var.k8s_version}"

    #etcd_servers     = "${join(",", formatlist("http://%s.master.k8s-%s-%s.internal:2389", var.endpoints_map[var.amount_masters], var.project, var.environment))}"

    #private_ip       = "${element(module.masters.instance_private_ip, count.index)}"

  }
}

resource "aws_s3_bucket_object" "kube_scheduler" {
  key     = "manifests/master/${count.index + 1}.master/kube-scheduler.yaml"
  bucket  = "${var.k8s_data_bucket}"
  content = "${element(data.template_file.kube_scheduler.*.rendered, count.index)}"
  count   = "${var.amount_masters}"
}

resource "aws_s3_bucket_object" "kube_api_policy" {
  key     = "manifests/master/${count.index + 1}.master/policy.jsonl"
  bucket  = "${var.k8s_data_bucket}"
  content = "${file("${path.module}/../templates/master/policy.jsonl")}"
  count   = "${var.amount_masters}"
}

resource "aws_s3_bucket_object" "kube_config" {
  key     = "manifests/master/${count.index + 1}.master/kubeconfig.yaml"
  bucket  = "${var.k8s_data_bucket}"
  content = "${file("${path.module}/../templates/master/kube-kubeconfig.tpl.yaml")}"
  count   = "${var.amount_masters}"
}

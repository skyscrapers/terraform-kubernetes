### KUBE-PROXY

data "template_file" "kube_proxy" {
  template = "${file("${path.module}/../templates/worker/kube-proxy.tpl.yaml")}"

  vars {
    project     = "${var.project}"
    environment = "${var.environment}"
    k8s_version = "${var.k8s_version}"
  }
}

resource "aws_s3_bucket_object" "kube_proxy" {
  key     = "manifests/worker/kube-proxy.yaml"
  bucket  = "${var.k8s_data_bucket}"
  content = "${data.template_file.kube_proxy.rendered}"
}

### KUBECONFIG

data "template_file" "kube_config" {
  template = "${file("${path.module}/../templates/worker/kubeconfig.tpl.yaml")}"

  vars {
    project     = "${var.project}"
    environment = "${var.environment}"
    k8s_version = "${var.k8s_version}"
  }
}

resource "aws_s3_bucket_object" "kube_config" {
  key     = "manifests/worker/kubeconfig.yaml"
  bucket  = "${var.k8s_data_bucket}"
  content = "${data.template_file.kube_config.rendered}"
}

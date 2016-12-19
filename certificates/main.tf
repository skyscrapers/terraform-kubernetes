data template_file "ca-csr" {
  template = "${file("${path.module}/templates/kubernetes/ca/ca-csr.tpl.json")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    city = "${var.city}"
    country = "${var.country}"
    state = "${var.state}"
    organization = "${var.organization}"
  }
}

data template_file "api-server-csr" {
  template = "${file("${path.module}/templates/kubernetes/api-server/kube-apiserver-server-csr.tpl.json")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    city = "${var.city}"
    country = "${var.country}"
    state = "${var.state}"
    organization = "${var.organization}"
  }
}

data template_file "kubelet-client-csr" {
  template = "${file("${path.module}/templates/kubernetes/kubelet/kubelet-client-csr.tpl.json")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    city = "${var.city}"
    country = "${var.country}"
    state = "${var.state}"
    organization = "${var.organization}"
  }
}

data template_file "proxy-csr" {
  template = "${file("${path.module}/templates/kubernetes/proxy/kube-proxy-client-csr.tpl.json")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    city = "${var.city}"
    country = "${var.country}"
    state = "${var.state}"
    organization = "${var.organization}"
  }
}

data template_file "controller-manager-csr" {
  template = "${file("${path.module}/templates/kubernetes/controller-manager/kube-controller-manager-client-csr.tpl.json")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    city = "${var.city}"
    country = "${var.country}"
    state = "${var.state}"
    organization = "${var.organization}"
  }
}

data template_file "admin-user-csr" {
  template = "${file("${path.module}/templates/kubernetes/admin/kubernetes-admin-user-csr.tpl.json")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    city = "${var.city}"
    country = "${var.country}"
    state = "${var.state}"
    organization = "${var.organization}"
  }
}

data template_file "scheduler-csr" {
  template = "${file("${path.module}/templates/kubernetes/scheduler/kube-scheduler-client-csr.tpl.json")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    city = "${var.city}"
    country = "${var.country}"
    state = "${var.state}"
    organization = "${var.organization}"
  }
}

resource "null_resource" "kubernetes_certificates" {

  provisioner "local-exec" {
    command = <<-EOC
      mkdir -p pki/kubernetes/ca
      mkdir -p pki/kubernetes/admin
      mkdir -p pki/kubernetes/api-server
      mkdir -p pki/kubernetes/controller-manager
      mkdir -p pki/kubernetes/kubelet
      mkdir -p pki/kubernetes/proxy
      mkdir -p pki/kubernetes/scheduler
      EOC
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee pki/kubernetes/ca/ca-csr.json <<EOF
      ${data.template_file.ca-csr.rendered}
      EOF
      cp ${path.module}/templates/kubernetes/ca/ca-config.json pki/kubernetes/ca/
      EOC
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee pki/kubernetes/api-server/kube-apiserver-server-csr.json <<EOF
      ${data.template_file.api-server-csr.rendered}
      EOF
      EOC
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee pki/kubernetes/proxy/kube-proxy-client-csr.json <<EOF
      ${data.template_file.proxy-csr.rendered}
      EOF
      EOC
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee pki/kubernetes/kubelet/kubelet-client-csr.json <<EOF
      ${data.template_file.kubelet-client-csr.rendered}
      EOF
      EOC
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee pki/kubernetes/controller-manager/kube-contoller-manager-client-csr.json <<EOF
      ${data.template_file.controller-manager-csr.rendered}
      EOF
      EOC
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee pki/kubernetes/admin/kubernetes-admin-user-csr.json <<EOF
      ${data.template_file.admin-user-csr.rendered}
      EOF
      EOC
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee pki/kubernetes/scheduler/kube-scheduler-client-csr.json <<EOF
      ${data.template_file.scheduler-csr.rendered}
      EOF
      EOC
  }

}

data template_file "etcd2-client" {
  template = "${file("${path.module}/templates/etcd2/client.tpl.json")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    city = "${var.city}"
    country = "${var.country}"
    state = "${var.state}"
    organization = "${var.organization}"
  }
}

data template_file "etcd2-peer" {
  template = "${file("${path.module}/templates/etcd2/peer.tpl.json")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    city = "${var.city}"
    country = "${var.country}"
    state = "${var.state}"
    organization = "${var.organization}"
  }
}

data template_file "etcd2-server" {
  template = "${file("${path.module}/templates/etcd2/server.tpl.json")}"

  vars {
    project = "${var.project}"
    environment = "${var.environment}"
    city = "${var.city}"
    country = "${var.country}"
    state = "${var.state}"
    organization = "${var.organization}"
  }
}

resource "null_resource" "etcd2_certificates" {

  provisioner "local-exec" {
    command = <<-EOC
      mkdir -p pki/etcd2
      EOC
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee pki/etcd2/client.json <<EOF
      ${data.template_file.etcd2-client.rendered}
      EOF
      EOC
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee pki/etcd2/peer.json <<EOF
      ${data.template_file.etcd2-peer.rendered}
      EOF
      EOC
  }

  provisioner "local-exec" {
    command = <<-EOC
      tee pki/etcd2/server.json <<EOF
      ${data.template_file.etcd2-server.rendered}
      EOF
      EOC
  }

}

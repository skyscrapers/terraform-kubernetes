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
      tee pki/kubernetes/controller-manager/kube-controller-manager-client-csr.json <<EOF
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

  provisioner "local-exec" {
    command = <<-EOC
      cd pki/kubernetes/ca
      cfssl gencert -initca ca-csr.json | cfssljson -bare ca
      cd ../api-server
      cfssl gencert -ca=../ca/ca.pem -ca-key=../ca/ca-key.pem -config=../ca/ca-config.json -profile=server kube-apiserver-server-csr.json | cfssljson -bare kube-apiserver-server
      cd ../kubelet
      cfssl gencert -ca=../ca/ca.pem -ca-key=../ca/ca-key.pem -config=../ca/ca-config.json -profile=client kubelet-client-csr.json | cfssljson -bare kubelet-client
      cd ../proxy
      cfssl gencert -ca=../ca/ca.pem -ca-key=../ca/ca-key.pem -config=../ca/ca-config.json -profile=client kube-proxy-client-csr.json | cfssljson -bare kube-proxy-client
      cd ../controller-manager
      cfssl gencert -ca=../ca/ca.pem -ca-key=../ca/ca-key.pem -config=../ca/ca-config.json -profile=client kube-controller-manager-client-csr.json | cfssljson -bare kube-controller-manager-client
      cd ../scheduler
      cfssl gencert -ca=../ca/ca.pem -ca-key=../ca/ca-key.pem -config=../ca/ca-config.json -profile=client kube-scheduler-client-csr.json | cfssljson -bare kube-scheduler-client
      cd ../admin
      cfssl gencert -ca=../ca/ca.pem -ca-key=../ca/ca-key.pem -config=../ca/ca-config.json -profile=client kubernetes-admin-user-csr.json | cfssljson -bare kubernetes-admin-user
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

  depends_on = ["null_resource.kubernetes_certificates"]

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

  provisioner "local-exec" {
    command = <<-EOC
      cd pki/etcd2
      cfssl gencert -ca=../kubernetes/ca/ca.pem -ca-key=../kubernetes/ca/ca-key.pem -config=../kubernetes/ca/ca-config.json -profile=server server.json | cfssljson -bare etcd2-server-server
      cfssl gencert -ca=../kubernetes/ca/ca.pem -ca-key=../kubernetes/ca/ca-key.pem -config=../kubernetes/ca/ca-config.json -profile=client peer.json | cfssljson -bare etcd2-peer-client
      cfssl gencert -ca=../kubernetes/ca/ca.pem -ca-key=../kubernetes/ca/ca-key.pem -config=../kubernetes/ca/ca-config.json -profile=client client.json | cfssljson -bare etcd2-client-client
      EOC
  }

}

resource "aws_s3_bucket" "k8s_data" {
  bucket = "${var.project}-${var.environment}-k8s-data"
  acl    = "private"
}

resource "aws_s3_bucket_object" "ca_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/ca/ca.pem"
  source = "${path.cwd}/pki/kubernetes/ca/ca.pem"
}

resource "aws_s3_bucket_object" "ca_key_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/ca/ca-key.pem"
  source = "${path.cwd}/pki/kubernetes/ca/ca-key.pem"
}

resource "aws_s3_bucket_object" "kubernetes_admin_user_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/admin/kubernetes-admin-user.pem"
  source = "${path.cwd}/pki/kubernetes/admin/kubernetes-admin-user.pem"
}

resource "aws_s3_bucket_object" "kubernetes_admin_user_key_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/admin/kubernetes-admin-user-key.pem"
  source = "${path.cwd}/pki/kubernetes/admin/kubernetes-admin-user-key.pem"
}

resource "aws_s3_bucket_object" "kube_apiserver_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/api-server/kube-apiserver-server.pem"
  source = "${path.cwd}/pki/kubernetes/api-server/kube-apiserver-server.pem"
}

resource "aws_s3_bucket_object" "kube_apiserver_key_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/api-server/kube-apiserver-server-key.pem"
  source = "${path.cwd}/pki/kubernetes/api-server/kube-apiserver-server-key.pem"
}

resource "aws_s3_bucket_object" "kube_controller_manager_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/controller-manager/kube-controller-manager-client.pem"
  source = "${path.cwd}/pki/kubernetes/controller-manager/kube-controller-manager-client.pem"
}

resource "aws_s3_bucket_object" "kube_controller_manager_key_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/controller-manager/kube-controller-manager-client-key.pem"
  source = "${path.cwd}/pki/kubernetes/controller-manager/kube-controller-manager-client-key.pem"
}

resource "aws_s3_bucket_object" "kubelet_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/kubelet/kubelet-client.pem"
  source = "${path.cwd}/pki/kubernetes/kubelet/kubelet-client.pem"
}

resource "aws_s3_bucket_object" "kubelet_key_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/kubelet/kubelet-client-key.pem"
  source = "${path.cwd}/pki/kubernetes/kubelet/kubelet-client-key.pem"
}

resource "aws_s3_bucket_object" "proxy_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/proxy/kube-proxy-client.pem"
  source = "${path.cwd}/pki/kubernetes/proxy/kube-proxy-client.pem"
}

resource "aws_s3_bucket_object" "proxy_key_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/proxy/kube-proxy-client-key.pem"
  source = "${path.cwd}/pki/kubernetes/proxy/kube-proxy-client-key.pem"
}

resource "aws_s3_bucket_object" "scheduler_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/scheduler/kube-scheduler-client.pem"
  source = "${path.cwd}/pki/kubernetes/scheduler/kube-scheduler-client.pem"
}

resource "aws_s3_bucket_object" "scheduler_key_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/kubernetes/scheduler/kube-scheduler-client-key.pem"
  source = "${path.cwd}/pki/kubernetes/scheduler/kube-scheduler-client-key.pem"
}

resource "aws_s3_bucket_object" "etcd2_client_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/etcd2/etcd2-client-client.pem"
  source = "${path.cwd}/pki/etcd2/etcd2-client-client.pem"
}

resource "aws_s3_bucket_object" "etcd2_client_key_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/etcd2/etcd2-client-client-key.pem"
  source = "${path.cwd}/pki/etcd2/etcd2-client-client-key.pem"
}

resource "aws_s3_bucket_object" "etcd2_peer_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/etcd2/etcd2-peer-client.pem"
  source = "${path.cwd}/pki/etcd2/etcd2-peer-client.pem"
}

resource "aws_s3_bucket_object" "etcd2_peer_key_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/etcd2/etcd2-peer-client-key.pem"
  source = "${path.cwd}/pki/etcd2/etcd2-peer-client-key.pem"
}

resource "aws_s3_bucket_object" "etcd2_server_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/etcd2/etcd2-server-server.pem"
  source = "${path.cwd}/pki/etcd2/etcd2-server-server.pem"
}

resource "aws_s3_bucket_object" "etcd2_server_key_pem" {
  depends_on = ["null_resource.kubernetes_certificates"]
  bucket = "${aws_s3_bucket.k8s_data.id}"
  key = "/pki/etcd2/etcd2-server-server-key.pem"
  source = "${path.cwd}/pki/etcd2/etcd2-server-server-key.pem"
}


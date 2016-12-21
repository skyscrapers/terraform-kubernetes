apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-apiserver
    image: quay.io/coreos/hyperkube:${k8s_version}
    command:
    - /hyperkube
    - apiserver
    - --bind-address=0.0.0.0
    - --insecure-bind-address=0.0.0.0
    - --etcd-servers=${etcd_servers}
    - --allow-privileged=true
    - --service-cluster-ip-range=${service_ip_range}
    - --service-node-port-range=30000-32767
    - --advertise-address=${private_ip}
    - --apiserver-count=3
    - --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota
    - --runtime-config=extensions/v1beta1=true,extensions/v1beta1/networkpolicies=true
    - --cloud-provider=aws
    - --secure-port=6443
    - --authorization-mode=ABAC
    - --authorization-policy-file=/etc/kubernetes/manifests/policy.jsonl
    - --client-ca-file=/etc/kubernetes/pki/ca/ca.pem
    - --tls-cert-file=/etc/kubernetes/pki/api-server/kube-apiserver-server.pem
    - --tls-private-key-file=/etc/kubernetes/pki/api-server/kube-apiserver-server-key.pem
    - --kubelet-certificate-authority=/etc/kubernetes/pki/ca/ca.pem
    - --kubelet-client-certificate=/etc/kubernetes/pki/kubelet/kubelet-client.pem
    - --kubelet-client-key=/etc/kubernetes/pki/kubelet/kubelet-client-key.pem

    ports:
    - containerPort: 6443
      hostPort: 6443
      name: https
    - containerPort: 8080
      hostPort: 8080
      name: local
    volumeMounts:
    - mountPath: /etc/kubernetes/pki
      name: pki-kubernetes
      readOnly: true
    - mountPath: /etc/kubernetes/manifests
      name: manifests-kubernetes
      readOnly: true
  volumes:
  - hostPath:
      path: /etc/kubernetes/pki
    name: pki-kubernetes
  - hostPath:
      path: /etc/kubernetes/manifests
    name: manifests-kubernetes

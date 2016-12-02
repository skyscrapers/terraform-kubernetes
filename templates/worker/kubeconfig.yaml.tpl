apiVersion: v1
kind: Config
clusters:
  - cluster:
      certificate-authority: /etc/kubernetes/pki/ca/ca.pem
      server: http://api.k8s-${project}-${environment}.internal:8080
    name: kubernetes
contexts:
  - context:
      cluster: kubernetes
      user: kubelet
    name: kubelet-to-kubernetes
current-context: kubelet-to-kubernetes
users:
  - name: kubelet
    user:
      client-certificate: /etc/kubernetes/pki/kubelet/kubelet-client.pem
      client-key: /etc/kubernetes/pki/kubelet/kubelet-client-key.pem

apiVersion: v1
kind: Config
clusters:
  - cluster:
      certificate-authority: /etc/kubernetes/pki/ca/ca.pem
      server: https://${api_elb}:6443
    name: kubernetes
contexts:
  - context:
      cluster: kubernetes
      user: kubelet-worker
    name: kubelet-to-kubernetes
current-context: kubelet-to-kubernetes
users:
  - name: kubelet-worker
    user:
      client-certificate: /etc/kubernetes/pki/kubelet-worker/kubelet-client.pem
      client-key: /etc/kubernetes/pki/kubelet-worker/kubelet-client-key.pem

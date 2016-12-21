apiVersion: v1
kind: Pod
metadata:
  name: kube-proxy
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-proxy
    image: quay.io/coreos/hyperkube:${k8s_version}
    command:
    - /hyperkube
    - proxy
    - --master=https://api.k8s-${project}-${environment}.internal:6443
    - --kubeconfig=/etc/kubernetes/manifests/kubeconfig.yaml
    - --proxy-mode=iptables
    securityContext:
      privileged: true
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

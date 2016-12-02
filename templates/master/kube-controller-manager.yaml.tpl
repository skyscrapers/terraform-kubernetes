apiVersion: v1
kind: Pod
metadata:
  name: kube-controller-manager
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: kube-controller-manager
    image: quay.io/coreos/hyperkube:${k8s_version}
    command:
    - /hyperkube
    - controller-manager
    - --allocate-node-cidrs=true
    - --cluster-cidr=${cluster_cidr}
    - --cloud-provider=aws
    - --cluster-name=kubernetes
    - --leader-elect=true
    - --master=http://127.0.0.1:8080
    - --service-cluster-ip-range=${service_ip_range}
    - --service-account-private-key-file=/etc/kubernetes/pki/api-server/kube-apiserver-server-key.pem
    - --root-ca-file=/etc/kubernetes/pki/ca/ca.pem
    - --v=2
    livenessProbe:
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 10252
      initialDelaySeconds: 15
      timeoutSeconds: 1
    volumeMounts:
    - mountPath: /etc/kubernetes/pki
      name: pki-kubernetes
      readOnly: true
  volumes:
  - hostPath:
      path: /etc/kubernetes/pki
    name: pki-kubernetes

[Service]
ExecStartPre=/usr/bin/mkdir -p /etc/kubernetes/manifests
ExecStartPre=/usr/bin/mkdir -p /var/log/containers

Environment=KUBELET_VERSION=v1.4.6_coreos.0
Environment="RKT_OPTS=--volume var-log,kind=host,source=/var/log \
  --mount volume=var-log,target=/var/log \
  --volume dns,kind=host,source=/etc/resolv.conf \
  --mount volume=dns,target=/etc/resolv.conf"

ExecStart=/usr/lib/coreos/kubelet-wrapper \
  --api-servers=http://api.k8s-int-test.internal:8080 \
  --network-plugin-dir=/etc/kubernetes/cni/net.d \
  --network-plugin= \
  --register-node=true \
  --allow-privileged=true \
  --config=/etc/kubernetes/manifests \
  --cluster-dns=10.100.0.2 \
  --cluster-domain=k8s-int-test.internal \
  --kubeconfig=/etc/kubernetes/worker-kubeconfig.yaml \
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target

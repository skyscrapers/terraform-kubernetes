#cloud-config

---
coreos:
  units:
  - name: manifest-copy.service
    command: start
    enable: true
    content: |
      [Unit]
      Description=AWS S3 Copy
      After=docker.service
      Requires=docker.service

      [Service]
      TimeoutStartSec=0
      Type=simple
      Restart=always
      RestartSec=10
      ExecStartPre=/usr/bin/docker pull mesosphere/aws-cli
      ExecStartPre=/usr/bin/docker run --rm -e "AWS_DEFAULT_REGION=eu-west-1" -v /etc/kubernetes:/project mesosphere/aws-cli \
        s3 cp --recursive s3://${project}-${environment}-k8s-data/pki/kubernetes/ pki/
      ExecStart=/usr/bin/docker run --rm -e "AWS_DEFAULT_REGION=eu-west-1" -v /etc/kubernetes:/project mesosphere/aws-cli \
        s3 cp --recursive s3://${project}-${environment}-k8s-data/manifests/worker/ manifests/

      [Install]
      WantedBy=multi-user.target
  - name: kubelet.service
    command: start
    enable: true
    content: |
      [Service]
      ExecStartPre=/usr/bin/mkdir -p /etc/kubernetes/manifests
      ExecStartPre=/usr/bin/mkdir -p /var/log/containers

      Environment=KUBELET_VERSION=${k8s_version}
      Environment="RKT_OPTS=--volume var-log,kind=host,source=/var/log \
        --mount volume=var-log,target=/var/log \
        --volume dns,kind=host,source=/etc/resolv.conf \
        --mount volume=dns,target=/etc/resolv.conf"

      ExecStart=/usr/lib/coreos/kubelet-wrapper \
        --api-servers=http://api.k8s-${project}-${environment}:8080 \
        --network-plugin-dir=/etc/kubernetes/cni/net.d \
        --network-plugin= \
        --register-node=true \
        --allow-privileged=true \
        --config=/etc/kubernetes/manifests \
        --cluster-dns=10.100.0.2 \
        --cluster-domain=k8s-${project}-${environment} \
        --kubeconfig=/etc/kubernetes/manifests/kubeconfig.yaml \
        --require-kubeconfig
      Restart=always
      RestartSec=10
      [Install]
      WantedBy=multi-user.target
  - name: docker-tcp.socket
    command: start
    enable: true
    content: |
      [Unit]
      Description=Docker Socket for the API

      [Socket]
      ListenStream=2375
      Service=docker.service
      BindIPv6Only=both

      [Install]
      WantedBy=sockets.target

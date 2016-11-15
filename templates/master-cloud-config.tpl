#cloud-config

---
hostname: ${master_num}.master.k8s-${project}-${environment}.internal
coreos:
  update:
    reboot-strategy: etcd-lock
  locksmith:
    etcd_cafile: /etc/etcd/ssl/ca.pem
    etcd_certfile: /etc/etcd/ssl/client.pem
    etcd_keyfile: /etc/etcd/ssl/client-key.pem
    endpoint: ${endpoints}
  etcd2:
    data-dir: /media/base
    election-timeout: 1200
    advertise-client-urls: https://${master_num}.master.k8s-${project}-${environment}.internal:2379
    initial-advertise-peer-urls: https://${master_num}.master.k8s-${project}-${environment}.internal:2380
    initial-cluster-state: new
    initial-cluster-token: int-test-k8s-master-token-1
    listen-client-urls: https://${master_num}.master.k8s-${project}-${environment}.internal:2379,https://127.0.0.1:2379
    listen-peer-urls: https://${master_num}.master.k8s-${project}-${environment}.internal:2380
    cert-file: /etc/etcd/ssl/server.pem
    client-cert-auth: true
    peer-client-cert-auth: true
    discovery-srv: k8s-${project}-${environment}.internal
    key-file: /etc/etcd/ssl/server-key.pem
    peer-cert-file: /etc/etcd/ssl/peer.pem
    peer-key-file: /etc/etcd/ssl/peer-key.pem
    peer-trusted-ca-file: /etc/etcd/ssl/ca.pem
    trusted-ca-file: /etc/etcd/ssl/ca.pem

  units:
  - name: media-base.mount
    enable: true
    command: start
    content: |
      [Unit]
      Before=etcd2.service
      Description = Mount for Etcd Storage
      [Install]
      RequiredBy=etcd2.service
      WantedBy=multi-user.target
      [Mount]
      What=/dev/xvdh
      Where=/media/base
      Type=ext4
  - name: etcd2.service
    command: start
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

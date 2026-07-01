#!/bin/bash
# Step 6: Bootstrap etcd Cluster
# Run this script ON EACH MASTER NODE individually via SSH
# OR use tmux to run on all 3 simultaneously
set -e

echo ""
echo "=========================================="
echo " STEP 6: Bootstrap etcd"
echo " (Run on each master node)"
echo "=========================================="

# ── Download etcd ──────────────────────────────────────────
echo "→ Downloading etcd v3.4.15..."
wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/v3.4.15/etcd-v3.4.15-linux-amd64.tar.gz"

tar -xvf etcd-v3.4.15-linux-amd64.tar.gz
sudo mv etcd-v3.4.15-linux-amd64/etcd* /usr/local/bin/

# ── Configure etcd directories ─────────────────────────────
echo "→ Configuring etcd..."
sudo mkdir -p /etc/etcd /var/lib/etcd
sudo chmod 700 /var/lib/etcd
sudo cp ca.pem master-kubernetes-key.pem master-kubernetes.pem /etc/etcd/

# ── Get instance metadata ──────────────────────────────────
export INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

ETCD_NAME=$(curl -s http://169.254.169.254/latest/user-data/ \
  | tr "|" "\n" | grep "^name" | cut -d"=" -f2)

echo "  INTERNAL_IP=$INTERNAL_IP"
echo "  ETCD_NAME=$ETCD_NAME"

# ── Create etcd systemd service ────────────────────────────
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster master-0=https://172.31.0.10:2380,master-1=https://172.31.0.11:2380,master-2=https://172.31.0.12:2380 \\
  --cert-file=/etc/etcd/master-kubernetes.pem \\
  --key-file=/etc/etcd/master-kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/master-kubernetes.pem \\
  --peer-key-file=/etc/etcd/master-kubernetes-key.pem \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ── Start etcd ─────────────────────────────────────────────
echo "→ Starting etcd..."
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd
}

# ── Verify ─────────────────────────────────────────────────
echo "→ Verifying etcd cluster members..."
sleep 5
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/master-kubernetes.pem \
  --key=/etc/etcd/master-kubernetes-key.pem

echo ""
echo "✅ etcd bootstrapped on this node!"

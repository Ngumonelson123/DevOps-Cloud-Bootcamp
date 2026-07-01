#!/bin/bash
# Step 3: Generate Self-Signed CA and All TLS Certificates
set -e
source "$(dirname "$0")/../../env.sh"
source "$(dirname "$0")/../../configs/network-ids.sh"

CERT_DIR="$(cd "$(dirname "$0")/../../configs/certificates" && pwd)"
mkdir -p ${CERT_DIR}
cd ${CERT_DIR}

echo ""
echo "=========================================="
echo " STEP 3: TLS Certificates"
echo "=========================================="

#1. Root Certificate Authority
echo "→ Generating Root CA..."
cat > ca-config.json <<EOF
{
  "signing": {
    "default": { "expiry": "8760h" },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "UK", "L": "England", "O": "Kubernetes",
               "OU": "Steghub.com DEVOPS", "ST": "London" }]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca
echo "  ✓ ca.pem, ca-key.pem"

#2. API Server Certificate
echo "→ Generating API Server certificate..."
cat > master-kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "172.31.0.10", "172.31.0.11", "172.31.0.12",
    "ip-172-31-0-10", "ip-172-31-0-11", "ip-172-31-0-12",
    "ip-172-31-0-10.${AWS_REGION}.compute.internal",
    "ip-172-31-0-11.${AWS_REGION}.compute.internal",
    "ip-172-31-0-12.${AWS_REGION}.compute.internal",
    "${KUBERNETES_PUBLIC_ADDRESS}",
    "kubernetes", "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "UK", "L": "England", "O": "Kubernetes",
               "OU": "StegHub.com DEVOPS", "ST": "London" }]
}
EOF

cfssl gencert \
  -ca=ca.pem -ca-key=ca-key.pem \
  -config=ca-config.json -profile=kubernetes \
  master-kubernetes-csr.json | cfssljson -bare master-kubernetes
echo "  ✓ master-kubernetes.pem"

#2. kube-scheduler
echo "→ Generating kube-scheduler certificate..."
cat > kube-scheduler-csr.json <<EOF
{ "CN": "system:kube-scheduler", "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "UK", "L": "England", "O": "system:kube-scheduler",
               "OU": "Steghub.com DEVOPS", "ST": "London" }] }
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
  -config=ca-config.json -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler
echo "  ✓ kube-scheduler.pem"

#2. kube-proxy
echo "→ Generating kube-proxy certificate..."
cat > kube-proxy-csr.json <<EOF
{ "CN": "system:kube-proxy", "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "UK", "L": "England", "O": "system:node-proxier",
               "OU": "Steghub.com DEVOPS", "ST": "London" }] }
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
  -config=ca-config.json -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy
echo "  ✓ kube-proxy.pem"

#2. kube-controller-manager
echo "→ Generating kube-controller-manager certificate..."
cat > kube-controller-manager-csr.json <<EOF
{ "CN": "system:kube-controller-manager", "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "UK", "L": "England", "O": "system:kube-controller-manager",
               "OU": "Steghub.com DEVOPS", "ST": "London" }] }
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
  -config=ca-config.json -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
echo "  ✓ kube-controller-manager.pem"

#6. kubelet (one per worker)
echo "→ Generating kubelet certificates (per worker)..."
for i in 0 1 2; do
  instance="${NAME}-worker-${i}"
  instance_hostname="ip-172-31-0-2${i}"

  cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance_hostname}",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "UK", "L": "England", "O": "system:nodes",
               "OU": "Steghub.com DEVOPS", "ST": "London" }]
}
EOF

  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  internal_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PrivateIpAddress')

  cfssl gencert \
    -ca=ca.pem -ca-key=ca-key.pem \
    -config=ca-config.json -profile=kubernetes \
    -hostname=${instance_hostname},${external_ip},${internal_ip} \
    ${instance}-csr.json | cfssljson -bare ${NAME}-worker-${i}

  echo "  ✓ ${NAME}-worker-${i}.pem"
done

#7. Admin user
echo "→ Generating admin certificate..."
cat > admin-csr.json <<EOF
{ "CN": "admin", "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "UK", "L": "England", "O": "system:masters",
               "OU": "Steghub.com DEVOPS", "ST": "London" }] }
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
  -config=ca-config.json -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
echo "  ✓ admin.pem"

#8. Service Account
echo "→ Generating service-account certificate..."
cat > service-account-csr.json <<EOF
{ "CN": "service-accounts", "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "UK", "L": "England", "O": "Kubernetes",
               "OU": "Steghub.com DEVOPS", "ST": "London" }] }
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
  -config=ca-config.json -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account
echo "  ✓ service-account.pem"

echo ""
echo "✅ All certificates generated in configs/certificates/"
ls -ltr *.pem

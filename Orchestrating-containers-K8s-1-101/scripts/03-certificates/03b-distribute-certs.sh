#!/bin/bash
# Step 3b: Distribute Certificates to Nodes
set -e
source "$(dirname "$0")/../../env.sh"
source "$(dirname "$0")/../../configs/network-ids.sh"

CERT_DIR="$(dirname "$0")/../../configs/certificates"
SSH_KEY="$(dirname "$0")/../../ssh/${NAME}.id_rsa"

echo ""
echo "=========================================="
echo " STEP 3b: Distribute Certificates"
echo "=========================================="

# Worker Nodes
echo "→ Sending certs to Worker nodes..."
for i in 0 1 2; do
  instance="${NAME}-worker-${i}"
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  echo "  worker-${i} ($external_ip)..."
  scp -i ${SSH_KEY} \
    -o StrictHostKeyChecking=no \
    -o IdentitiesOnly=yes \
    ${CERT_DIR}/ca.pem \
    ${CERT_DIR}/${NAME}-worker-${i}-key.pem \
    ${CERT_DIR}/${NAME}-worker-${i}.pem \
    ubuntu@${external_ip}:~/
done

# Master Nodes
echo "→ Sending certs to Master nodes..."
for i in 0 1 2; do
  instance="${NAME}-master-${i}"
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  echo "  master-${i} ($external_ip)..."
  scp -i ${SSH_KEY} \
    -o StrictHostKeyChecking=no \
    -o IdentitiesOnly=yes \
    ${CERT_DIR}/ca.pem \
    ${CERT_DIR}/ca-key.pem \
    ${CERT_DIR}/service-account-key.pem \
    ${CERT_DIR}/service-account.pem \
    ${CERT_DIR}/master-kubernetes.pem \
    ${CERT_DIR}/master-kubernetes-key.pem \
    ubuntu@${external_ip}:~/
done

echo ""
echo "✅ Certificates distributed to all nodes!"

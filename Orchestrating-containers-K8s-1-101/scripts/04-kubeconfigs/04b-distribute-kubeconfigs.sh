#!/bin/bash
# Step 4b: Distribute Kubeconfigs to Nodes
set -e
source "$(dirname "$0")/../../env.sh"
source "$(dirname "$0")/../../configs/network-ids.sh"

KUBE_DIR="$(dirname "$0")/../../configs/kubeconfigs"
SSH_KEY="$(dirname "$0")/../../ssh/${NAME}.id_rsa"

echo ""
echo "=========================================="
echo " STEP 4b: Distribute Kubeconfigs"
echo "=========================================="

#Worker nodes
echo "→ Sending kubeconfigs to Worker nodes..."
for i in 0 1 2; do
  instance="${NAME}-worker-${i}"
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  echo "  worker-${i} ($external_ip)..."
  scp -i ${SSH_KEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes \
    ${KUBE_DIR}/${instance}.kubeconfig \
    ${KUBE_DIR}/kube-proxy.kubeconfig \
    ubuntu@${external_ip}:~/
done

#Master nodes
echo "→ Sending kubeconfigs to Master nodes..."
for i in 0 1 2; do
  instance="${NAME}-master-${i}"
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  echo "  master-${i} ($external_ip)..."
  scp -i ${SSH_KEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes \
    ${KUBE_DIR}/admin.kubeconfig \
    ${KUBE_DIR}/kube-controller-manager.kubeconfig \
    ${KUBE_DIR}/kube-scheduler.kubeconfig \
    ubuntu@${external_ip}:~/
done

echo ""
echo "✅ Kubeconfigs distributed!"

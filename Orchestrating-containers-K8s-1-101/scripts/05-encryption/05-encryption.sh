#!/bin/bash
# Step 5: etcd Encryption at Rest
set -e
source "$(dirname "$0")/../../env.sh"
source "$(dirname "$0")/../../configs/network-ids.sh"

CERT_DIR="$(dirname "$0")/../../configs/certificates"
SSH_KEY="$(dirname "$0")/../../ssh/${NAME}.id_rsa"

echo ""
echo "=========================================="
echo " STEP 5: etcd Encryption at Rest"
echo "=========================================="

ETCD_ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64 | tr -d '\n')
echo "→ Generated encryption key"

cat > ${CERT_DIR}/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ETCD_ENCRYPTION_KEY}
      - identity: {}
EOF

echo "→ Distributing encryption config to masters..."
for i in 0 1 2; do
  instance="${NAME}-master-${i}"
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  scp -i ${SSH_KEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes \
    ${CERT_DIR}/encryption-config.yaml \
    ubuntu@${external_ip}:~/

  # Distribute NLB DNS so step 7 can use it without a hardcoded value
  echo "${KUBERNETES_PUBLIC_ADDRESS}" | ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes \
    ubuntu@${external_ip} 'cat > ~/kubernetes-public-address.txt'

  echo "  ✓ master-${i} ($external_ip)"
done

echo ""
echo "✅ Encryption config created and distributed!"

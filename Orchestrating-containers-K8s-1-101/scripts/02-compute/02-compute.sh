#!/bin/bash
# Step 2: Create Compute Resources (EC2 Instances)
set -e
source "$(dirname "$0")/../../env.sh"
source "$(dirname "$0")/../../configs/network-ids.sh"

echo ""
echo "=========================================="
echo " STEP 2: Compute Resources"
echo "=========================================="

#1. Get Ubuntu 20.04 AMI
echo "→ Getting Ubuntu AMI..."
IMAGE_ID=$(aws ec2 describe-images --owners 099720109477 \
  --filters \
  'Name=root-device-type,Values=ebs' \
  'Name=architecture,Values=x86_64' \
  'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*' \
  | jq -r '.Images|sort_by(.Name)[-1].ImageId')
echo "  IMAGE_ID=$IMAGE_ID"

#2. SSH Key Pair
echo "→ Creating SSH Key Pair..."
mkdir -p "$(dirname "$0")/../../ssh"

aws ec2 create-key-pair \
  --key-name ${NAME} \
  --output text --query 'KeyMaterial' \
  > "$(dirname "$0")/../../ssh/${NAME}.id_rsa"

chmod 600 "$(dirname "$0")/../../ssh/${NAME}.id_rsa"
echo "  Key saved to ssh/${NAME}.id_rsa"

#3. Master Nodes (Control Plane)
echo "→ Creating 3 Master nodes..."
for i in 0 1 2; do
  instance_id=$(aws ec2 run-instances \
    --associate-public-ip-address \
    --image-id ${IMAGE_ID} \
    --count 1 \
    --key-name ${NAME} \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --instance-type t3.small \
    --private-ip-address 172.31.0.1${i} \
    --user-data "name=master-${i}" \
    --subnet-id ${SUBNET_ID} \
    --output text --query 'Instances[].InstanceId')

  aws ec2 modify-instance-attribute \
    --instance-id ${instance_id} \
    --no-source-dest-check

  aws ec2 create-tags \
    --resources ${instance_id} \
    --tags "Key=Name,Value=${NAME}-master-${i}"

  echo "  master-${i}: $instance_id (172.31.0.1${i})"
done

#4. Worker Nodes
echo "→ Creating 3 Worker nodes..."
for i in 0 1 2; do
  instance_id=$(aws ec2 run-instances \
    --associate-public-ip-address \
    --image-id ${IMAGE_ID} \
    --count 1 \
    --key-name ${NAME} \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --instance-type t3.small \
    --private-ip-address 172.31.0.2${i} \
    --user-data "name=worker-${i}|pod-cidr=172.20.${i}.0/24" \
    --subnet-id ${SUBNET_ID} \
    --output text --query 'Instances[].InstanceId')

  aws ec2 modify-instance-attribute \
    --instance-id ${instance_id} \
    --no-source-dest-check

  aws ec2 create-tags \
    --resources ${instance_id} \
    --tags "Key=Name,Value=${NAME}-worker-${i}"

  echo "  worker-${i}: $instance_id (172.31.0.2${i})"
done

# Save IMAGE_ID
echo "export IMAGE_ID=\"${IMAGE_ID}\"" >> "$(dirname "$0")/../../configs/network-ids.sh"

echo ""
echo "✅ Compute resources created!"
echo "   Waiting ~60s for instances to be reachable..."
sleep 60
echo "   Done. Proceed to Step 3 (certificates)."

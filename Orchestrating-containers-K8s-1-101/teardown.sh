#!/bin/bash
# Teardown: Destroy all AWS resources for k8s-cluster-from-ground-up
set -e
source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/configs/network-ids.sh"

echo ""
echo "=========================================="
echo " TEARDOWN: Destroying all resources"
echo "=========================================="
echo ""
echo "⚠️  This will permanently delete all EC2 instances,"
echo "   the NLB, VPC, and all associated resources."
echo ""
read -p "Type 'yes' to confirm: " confirm
[[ "$confirm" != "yes" ]] && echo "Aborted." && exit 0

# 1. Terminate EC2 instances
echo ""
echo "→ Terminating EC2 instances..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${NAME}-master-*" \
            "Name=instance-state-name,Values=running,stopped,pending" \
  --query "Reservations[].Instances[].InstanceId" --output text)

WORKER_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${NAME}-worker-*" \
            "Name=instance-state-name,Values=running,stopped,pending" \
  --query "Reservations[].Instances[].InstanceId" --output text)

ALL_IDS="$INSTANCE_IDS $WORKER_IDS"
if [[ -n "${ALL_IDS// }" ]]; then
  aws ec2 terminate-instances --instance-ids $ALL_IDS --output text --query 'TerminatingInstances[].InstanceId'
  echo "  Waiting for instances to terminate..."
  aws ec2 wait instance-terminated --instance-ids $ALL_IDS
  echo "  ✓ All instances terminated"
else
  echo "  No instances found"
fi

# 2. Delete SSH key pair
echo "→ Deleting SSH key pair..."
aws ec2 delete-key-pair --key-name ${NAME} 2>/dev/null && echo "  ✓ Key pair deleted" || echo "  Key pair not found"
rm -f ssh/${NAME}.id_rsa

# 3. Delete NLB listener + load balancer
echo "→ Deleting NLB listener..."
LISTENER_ARN=$(aws elbv2 describe-listeners \
  --load-balancer-arn ${LOAD_BALANCER_ARN} \
  --query "Listeners[].ListenerArn" --output text 2>/dev/null || echo "")
[[ -n "$LISTENER_ARN" ]] && aws elbv2 delete-listener --listener-arn ${LISTENER_ARN} && echo "  ✓ Listener deleted"

echo "→ Deleting NLB..."
aws elbv2 delete-load-balancer --load-balancer-arn ${LOAD_BALANCER_ARN} 2>/dev/null && echo "  ✓ NLB deleted" || echo "  NLB not found"
echo "  Waiting for NLB to be deleted..."
sleep 15

# 4. Delete target group
echo "→ Deleting Target Group..."
aws elbv2 delete-target-group --target-group-arn ${TARGET_GROUP_ARN} 2>/dev/null && echo "  ✓ Target group deleted" || echo "  Target group not found"

# 5. Delete security group
echo "→ Deleting Security Group..."
aws ec2 delete-security-group --group-id ${SECURITY_GROUP_ID} 2>/dev/null && echo "  ✓ Security group deleted" || echo "  Security group not found"

# 6. Detach and delete internet gateway
echo "→ Detaching Internet Gateway..."
aws ec2 detach-internet-gateway \
  --internet-gateway-id ${INTERNET_GATEWAY_ID} \
  --vpc-id ${VPC_ID} 2>/dev/null && echo "  ✓ IGW detached" || echo "  IGW not found"

echo "→ Deleting Internet Gateway..."
aws ec2 delete-internet-gateway \
  --internet-gateway-id ${INTERNET_GATEWAY_ID} 2>/dev/null && echo "  ✓ IGW deleted" || echo "  IGW not found"

# 7. Delete subnet
echo "→ Deleting Subnet..."
aws ec2 delete-subnet --subnet-id ${SUBNET_ID} 2>/dev/null && echo "  ✓ Subnet deleted" || echo "  Subnet not found"

# 8. Delete route table
echo "→ Deleting Route Table..."
aws ec2 delete-route-table --route-table-id ${ROUTE_TABLE_ID} 2>/dev/null && echo "  ✓ Route table deleted" || echo "  Route table not found"

# 9. Delete VPC
echo "→ Deleting VPC..."
aws ec2 delete-vpc --vpc-id ${VPC_ID} 2>/dev/null && echo "  ✓ VPC deleted" || echo "  VPC not found"

# 10. Clean up local generated files
echo "→ Cleaning up local files..."
rm -f configs/network-ids.sh
rm -f configs/certificates/*.pem configs/certificates/*.json configs/certificates/*.csr
rm -f configs/kubeconfigs/*.kubeconfig
rm -f configs/certificates/encryption-config.yaml
echo "  ✓ Local configs cleaned"

echo ""
echo "✅ All resources destroyed!"

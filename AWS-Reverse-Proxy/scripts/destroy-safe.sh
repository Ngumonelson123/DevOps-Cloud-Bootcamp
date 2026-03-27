#!/bin/bash
# ============================================================
#  scripts/destroy-safe.sh
#  Safe wrapper around terraform destroy with cost reminder
#  and resource listing before you confirm.
#
#  Usage: ./scripts/destroy-safe.sh
# ============================================================

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║           ⚠  TERRAFORM DESTROY WARNING  ⚠            ║"
echo "║                                                      ║"
echo "║  This will PERMANENTLY DELETE all resources.         ║"
echo "║  Make sure you have completed your project work!     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

cd "$(dirname "$0")/.." || exit 1

# List running resources with estimated cost
echo -e "${YELLOW}Currently running resources:${NC}"
echo ""

echo "── EC2 Instances ──────────────────────────────────────"
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=rproxy" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].{Name:Tags[?Key==`Name`].Value|[0],Type:InstanceType,AZ:Placement.AvailabilityZone,IP:PrivateIpAddress}' \
  --output table 2>/dev/null

echo ""
echo "── Load Balancers ─────────────────────────────────────"
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].{Name:LoadBalancerName,Type:Type,Scheme:Scheme,State:State.Code}' \
  --output table 2>/dev/null

echo ""
echo "── RDS Instances ──────────────────────────────────────"
aws rds describe-db-instances \
  --query 'DBInstances[*].{ID:DBInstanceIdentifier,Class:DBInstanceClass,Status:DBInstanceStatus,Engine:Engine}' \
  --output table 2>/dev/null

echo ""
echo "── NAT Gateways ───────────────────────────────────────"
aws ec2 describe-nat-gateways \
  --filter "Name=tag:Project,Values=rproxy" \
           "Name=state,Values=available" \
  --query 'NatGateways[*].{ID:NatGatewayId,State:State,Subnet:SubnetId}' \
  --output table 2>/dev/null

echo ""
echo -e "${YELLOW}Estimated hourly cost while these resources run: ~\$3-4/hr${NC}"
echo -e "${YELLOW}Estimated monthly cost if left running:          ~\$95/month${NC}"
echo ""

read -p "Are you absolutely sure you want to destroy everything? Type 'yes' to confirm: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo -e "${GREEN}Destroy cancelled. Your resources are still running.${NC}"
  exit 0
fi

echo ""
echo -e "${RED}Starting terraform destroy...${NC}"
echo ""

terraform destroy \
  -var="db_password=$(grep db_password terraform.tfvars | cut -d'"' -f2)" \
  -var="db_username=$(grep db_username terraform.tfvars | cut -d'"' -f2)"

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════╗"
  echo "║         All resources destroyed successfully!        ║"
  echo "║         You will no longer be charged for these.     ║"
  echo -e "╚══════════════════════════════════════════════════════╝${NC}"
else
  echo ""
  echo -e "${RED}Destroy encountered errors. Check the output above.${NC}"
  echo "Some resources may still be running – check the AWS Console."
  exit 1
fi

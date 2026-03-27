#!/bin/bash
# ============================================================
#  scripts/sync-tf-to-ansible.sh
#  After terraform apply, pulls outputs and writes them
#  into ansible/inventory/group_vars/all.yml automatically.
#
#  Usage: ./scripts/sync-tf-to-ansible.sh
# ============================================================

set -e
GREEN='\033[0;32m'
NC='\033[0m'

cd "$(dirname "$0")/.." || exit 1

echo "Reading Terraform outputs..."

EFS_ID=$(terraform output -raw efs_id 2>/dev/null)
INT_ALB=$(terraform output -raw internal_alb_dns 2>/dev/null)
EXT_ALB=$(terraform output -raw external_alb_dns 2>/dev/null)
RDS_EP=$(terraform output -raw rds_endpoint 2>/dev/null | cut -d: -f1)
BASTION_IPS=$(terraform output -json bastion_eips 2>/dev/null | python3 -c "import sys,json; ips=json.load(sys.stdin); print(ips[0])")

echo "  EFS ID:        $EFS_ID"
echo "  Internal ALB:  $INT_ALB"
echo "  RDS Endpoint:  $RDS_EP"
echo "  Bastion IP:    $BASTION_IPS"

# Update group_vars/all.yml
VARS_FILE="ansible/inventory/group_vars/all.yml"

sed -i "s|efs_id:.*|efs_id: \"$EFS_ID\"|" "$VARS_FILE"
sed -i "s|internal_alb_dns:.*|internal_alb_dns: \"$INT_ALB\"|" "$VARS_FILE"
sed -i "s|rds_endpoint:.*|rds_endpoint: \"$RDS_EP\"|" "$VARS_FILE"

# Update ansible.cfg ProxyJump with real Bastion IP
sed -i "s|ProxyJump=ec2-user@[0-9.]*|ProxyJump=ec2-user@$BASTION_IPS|" \
  "ansible/ansible.cfg"

echo ""
echo -e "${GREEN}✓ Ansible vars updated from Terraform outputs${NC}"
echo ""
echo "Next step: run the Ansible playbook:"
echo "  cd ansible"
echo "  ansible-playbook playbooks/site.yml"

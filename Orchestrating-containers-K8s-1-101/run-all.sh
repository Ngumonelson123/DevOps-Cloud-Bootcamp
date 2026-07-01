#!/bin/bash
# run-all.sh
# Orchestrates the full cluster setup from your local machine.
# Run each function one at a time.
source ./env.sh
source ./configs/network-ids.sh 2>/dev/null || true

SSH_KEY="./ssh/${NAME}.id_rsa"

# Helper: get master public IP
master_ip() {
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${NAME}-master-${1}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress'
}

# Helper: get worker public IP
worker_ip() {
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${NAME}-worker-${1}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress'
}

# SSH into a node
ssh_master() { ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ubuntu@$(master_ip $1); }
ssh_worker() { ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ubuntu@$(worker_ip $1); }

# Run a script on all masters (sequentially)
run_on_all_masters() {
  local script=$1
  for i in 0 1 2; do
    echo "========== Master $i =========="
    ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ubuntu@$(master_ip $i) 'bash -s' < ${script}
  done
}

# Run a script on all workers (sequentially)
run_on_all_workers() {
  local script=$1
  for i in 0 1 2; do
    echo "========== Worker $i =========="
    ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ubuntu@$(worker_ip $i) 'bash -s' < ${script}
  done
}

echo ""
echo "============================================"
echo " K8s From Ground Up — Orchestration Runner"
echo "============================================"
echo ""
echo "Usage:"
echo "  source run-all.sh            # load helpers"
echo "  ssh_master 0                 # SSH into master-0"
echo "  ssh_worker 1                 # SSH into worker-1"
echo "  run_on_all_masters <script>  # run script on all masters"
echo "  run_on_all_workers <script>  # run script on all workers"
echo ""
echo "Execution order:"
echo "  1. bash scripts/01-network/01-network.sh"
echo "  2. bash scripts/02-compute/02-compute.sh"
echo "  3. bash scripts/03-certificates/03-certificates.sh"
echo "  4. bash scripts/03-certificates/03b-distribute-certs.sh"
echo "  5. bash scripts/04-kubeconfigs/04-kubeconfigs.sh"
echo "  6. bash scripts/04-kubeconfigs/04b-distribute-kubeconfigs.sh"
echo "  7. bash scripts/05-encryption/05-encryption.sh"
echo "  8. run_on_all_masters scripts/06-etcd/06-etcd-on-master.sh"
echo "  9. run_on_all_masters scripts/07-control-plane/07-control-plane-on-master.sh"
echo " 10. bash scripts/07-control-plane/07b-rbac.sh"
echo " 11. run_on_all_workers scripts/08-worker-nodes/08-worker-on-node.sh"
echo ""
echo "Verify:"
echo "  kubectl get nodes --kubeconfig configs/kubeconfigs/admin.kubeconfig"

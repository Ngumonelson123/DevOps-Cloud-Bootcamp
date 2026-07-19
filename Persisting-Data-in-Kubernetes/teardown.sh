#!/bin/bash
# Tears down everything created for this project: the EKS cluster
# (which removes its nodegroup, VPC, and dynamically-provisioned EBS
# volumes) plus the manually-created EBS volume from the static PV demo.
set -euo pipefail

export AWS_PROFILE=${AWS_PROFILE:-kubestronaut}
export AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER=steghub-persist-eks

echo "==> Deleting manually-created EBS volume tagged Name=${CLUSTER}-manual-pv (if any)"
VOL_ID=$(aws ec2 describe-volumes \
  --filters "Name=tag:Name,Values=${CLUSTER}-manual-pv" \
  --query 'Volumes[0].VolumeId' --output text 2>/dev/null || true)
if [ "${VOL_ID}" != "None" ] && [ -n "${VOL_ID}" ]; then
  aws ec2 delete-volume --volume-id "${VOL_ID}" && echo "Deleted ${VOL_ID}"
else
  echo "No manual volume found."
fi

echo "==> Deleting EKS cluster ${CLUSTER} (this removes nodegroup, VPC, dynamic EBS volumes via PV reclaim)"
eksctl delete cluster -f eks-cluster.yaml

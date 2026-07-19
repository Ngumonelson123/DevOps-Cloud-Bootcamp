#!/bin/bash
# Creates an EBS volume pinned to the AZ of one node, then patches
# manifests/01-manual-pv-pvc-pod.yaml with the real volume ID.
# This is the "static provisioning" step used to demonstrate the
# AZ-pinning limitation before moving to dynamic provisioning.
set -euo pipefail

export AWS_PROFILE=${AWS_PROFILE:-kubestronaut}
export AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER=steghub-persist-eks

NODE_AZ=$(kubectl get nodes -o jsonpath='{.items[0].metadata.labels.topology\.kubernetes\.io/zone}')
echo "Creating 5Gi gp3 volume in AZ: ${NODE_AZ}"

VOLUME_ID=$(aws ec2 create-volume \
  --availability-zone "${NODE_AZ}" \
  --size 5 \
  --volume-type gp3 \
  --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=${CLUSTER}-manual-pv}]" \
  --query 'VolumeId' --output text)

echo "Created volume: ${VOLUME_ID}"
echo "Waiting for it to become available..."
aws ec2 wait volume-available --volume-ids "${VOLUME_ID}"

sed -i "s/REPLACE_WITH_VOLUME_ID/${VOLUME_ID}/" ../manifests/01-manual-pv-pvc-pod.yaml
echo "Patched manifests/01-manual-pv-pvc-pod.yaml with volumeHandle: ${VOLUME_ID}"

#!/bin/bash
# EKS 1.23+ has no in-tree EBS provisioner, so dynamic provisioning
# (StorageClass -> PVC -> auto-created EBS volume) requires the
# aws-ebs-csi-driver addon plus an IRSA role that lets it call the EC2 API.
set -euo pipefail

export AWS_PROFILE=${AWS_PROFILE:-kubestronaut}
export AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER=steghub-persist-eks

echo "==> Associating IAM OIDC provider with the cluster"
eksctl utils associate-iam-oidc-provider --cluster "${CLUSTER}" --approve

echo "==> Creating IRSA service account for the EBS CSI controller"
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster "${CLUSTER}" \
  --role-name AmazonEKS_EBS_CSI_DriverRole_persist \
  --role-only \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole_persist"

echo "==> Installing the aws-ebs-csi-driver EKS addon (role: ${ROLE_ARN})"
eksctl create addon \
  --cluster "${CLUSTER}" \
  --name aws-ebs-csi-driver \
  --service-account-role-arn "${ROLE_ARN}" \
  --force

echo "==> Waiting for the CSI controller pods to become ready"
kubectl -n kube-system rollout status deployment/ebs-csi-controller --timeout=180s

echo "Done. Default StorageClasses:"
kubectl get storageclass

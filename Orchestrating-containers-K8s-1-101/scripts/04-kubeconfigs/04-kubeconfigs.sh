#!/bin/bash
# Step 4: Generate Kubeconfig Files
set -e
source "$(dirname "$0")/../../env.sh"
source "$(dirname "$0")/../../configs/network-ids.sh"

CERT_DIR="$(cd "$(dirname "$0")/../../configs/certificates" && pwd)"
KUBE_DIR="$(cd "$(dirname "$0")/../../configs/kubeconfigs" && pwd)"
mkdir -p ${KUBE_DIR}
cd ${CERT_DIR}

echo ""
echo "=========================================="
echo " STEP 4: Kubeconfig Files"
echo "=========================================="

KUBERNETES_API_SERVER_ADDRESS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns ${LOAD_BALANCER_ARN} \
  --output text --query 'LoadBalancers[].DNSName')

echo "  API Server: $KUBERNETES_API_SERVER_ADDRESS"

#1. kubelet kubeconfigs (per worker)
echo "→ Generating kubelet kubeconfigs..."
for i in 0 1 2; do
  instance="${NAME}-worker-${i}"
  instance_hostname="ip-172-31-0-2${i}"

  kubectl config set-cluster ${NAME} \
    --certificate-authority=ca.pem --embed-certs=true \
    --server=https://${KUBERNETES_API_SERVER_ADDRESS}:6443 \
    --kubeconfig=${KUBE_DIR}/${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance_hostname} \
    --client-certificate=${NAME}-worker-${i}.pem \
    --client-key=${NAME}-worker-${i}-key.pem \
    --embed-certs=true \
    --kubeconfig=${KUBE_DIR}/${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=${NAME} \
    --user=system:node:${instance_hostname} \
    --kubeconfig=${KUBE_DIR}/${instance}.kubeconfig

  kubectl config use-context default \
    --kubeconfig=${KUBE_DIR}/${instance}.kubeconfig

  echo "  ✓ ${instance}.kubeconfig"
done

#2. kube-proxy kubeconfig
echo "→ Generating kube-proxy kubeconfig..."
{
  kubectl config set-cluster ${NAME} \
    --certificate-authority=ca.pem --embed-certs=true \
    --server=https://${KUBERNETES_API_SERVER_ADDRESS}:6443 \
    --kubeconfig=${KUBE_DIR}/kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=${KUBE_DIR}/kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=${NAME} --user=system:kube-proxy \
    --kubeconfig=${KUBE_DIR}/kube-proxy.kubeconfig

  kubectl config use-context default \
    --kubeconfig=${KUBE_DIR}/kube-proxy.kubeconfig
}
echo "  ✓ kube-proxy.kubeconfig"

#3. kube-controller-manager kubeconfig
echo "→ Generating kube-controller-manager kubeconfig..."
{
  kubectl config set-cluster ${NAME} \
    --certificate-authority=ca.pem --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=${KUBE_DIR}/kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=${KUBE_DIR}/kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=${NAME} --user=system:kube-controller-manager \
    --kubeconfig=${KUBE_DIR}/kube-controller-manager.kubeconfig

  kubectl config use-context default \
    --kubeconfig=${KUBE_DIR}/kube-controller-manager.kubeconfig
}
echo "  ✓ kube-controller-manager.kubeconfig"

#4. kube-scheduler kubeconfig
echo "→ Generating kube-scheduler kubeconfig..."
{
  kubectl config set-cluster ${NAME} \
    --certificate-authority=ca.pem --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=${KUBE_DIR}/kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=${KUBE_DIR}/kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=${NAME} --user=system:kube-scheduler \
    --kubeconfig=${KUBE_DIR}/kube-scheduler.kubeconfig

  kubectl config use-context default \
    --kubeconfig=${KUBE_DIR}/kube-scheduler.kubeconfig
}
echo "  ✓ kube-scheduler.kubeconfig"

# 5. admin kubeconfig
echo "→ Generating admin kubeconfig..."
{
  kubectl config set-cluster ${NAME} \
    --certificate-authority=ca.pem --embed-certs=true \
    --server=https://${KUBERNETES_API_SERVER_ADDRESS}:6443 \
    --kubeconfig=${KUBE_DIR}/admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=${KUBE_DIR}/admin.kubeconfig

  kubectl config set-context default \
    --cluster=${NAME} --user=admin \
    --kubeconfig=${KUBE_DIR}/admin.kubeconfig

  kubectl config use-context default \
    --kubeconfig=${KUBE_DIR}/admin.kubeconfig
}
echo "  ✓ admin.kubeconfig"

echo ""
echo "✅ All kubeconfigs generated in configs/kubeconfigs/"
ls -ltr ${KUBE_DIR}/*.kubeconfig

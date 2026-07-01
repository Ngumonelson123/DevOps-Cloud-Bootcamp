#!/bin/bash
# ============================================================
# Step 7b: Configure RBAC for Kubelet Authorization
# Run from your LOCAL machine (not on the master)
# ============================================================
set -e
source "$(dirname "$0")/../../env.sh"
source "$(dirname "$0")/../../configs/network-ids.sh"

KUBE_DIR="$(dirname "$0")/../../configs/kubeconfigs"

echo ""
echo "=========================================="
echo " STEP 7b: RBAC for Kubelet Authorization"
echo "=========================================="

echo "→ Creating ClusterRole..."
cat <<EOF | kubectl apply --kubeconfig ${KUBE_DIR}/admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups: [""]
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs: ["*"]
EOF

echo "→ Creating ClusterRoleBinding..."
cat <<EOF | kubectl apply --kubeconfig ${KUBE_DIR}/admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF

echo ""
echo "✅ RBAC configured!"
kubectl get namespaces --kubeconfig ${KUBE_DIR}/admin.kubeconfig

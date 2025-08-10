#!/bin/bash

set -e

CLUSTER_NAME="${1:-}"
REGION="${2:-}"
PROJECT_NAME="${3:-}"

: "${CLUSTER_NAME:?Missing cluster name}"
: "${REGION:?Missing region}"
: "${PROJECT_NAME:?Missing project name}"

log() {
    echo "[INFO] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

for cmd in aws kubectl; do
    command -v $cmd > /dev/null 2>&1 || {
        log_error "Required command '$cmd' not found. Pleade install it."
        exit 1
    }
done

log "Updating Kubeconfig For Cluster: $CLUSTER_NAME ..."
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION


log "Applying Admin Cluster Role Binding..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: "$PROJECT_NAME-admin"
subjects:
- kind: Group
  name: "$PROJECT_NAME-admin"
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

log "Cluster Role Binding Applied Successfully."
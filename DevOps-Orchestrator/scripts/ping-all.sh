#!/usr/bin/env bash
# ping-all.sh — verify Ansible can reach all servers
# Usage: ./scripts/ping-all.sh [ci|dev]
# Default: runs against both environments

set -e

ANSIBLE_DIR="$(dirname "$0")/../ansible"
ENV=${1:-"all"}

cd "$ANSIBLE_DIR"

if [[ "$ENV" == "ci" || "$ENV" == "all" ]]; then
    echo "==> Pinging CI environment..."
    ansible all -i inventory/ci -m ping
fi

if [[ "$ENV" == "dev" || "$ENV" == "all" ]]; then
    echo ""
    echo "==> Pinging Dev environment..."
    ansible all -i inventory/dev -m ping
fi

echo ""
echo "All hosts reachable!"

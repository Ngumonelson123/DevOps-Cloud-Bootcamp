#!/bin/bash
# Project: Orchestrating containers across multiple
#          Virtual Servers with Kubernetes 1-101
# Source this file before running any script:
#   source env.sh

export AWS_PROFILE=kubestronaut
export AWS_REGION=us-east-1
export NAME=k8s-cluster-from-ground-up

# These will be populated as you run each step
# Do not set them here — they are written to configs/network-ids.sh by each script

echo "✅ Environment loaded for project: $NAME"
echo "   AWS Profile : $AWS_PROFILE"
echo "   AWS Region  : $AWS_REGION"

#!/bin/bash
# Step 1: Configure Network Infrastructure
set -e
source "$(dirname "$0")/../../env.sh"

echo ""
echo "=========================================="
echo " STEP 1: Network Infrastructure"
echo "=========================================="

#1. Create VPC
echo ""
echo "→ Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 172.31.0.0/16 \
  --output text --query 'Vpc.VpcId')
echo "  VPC_ID=$VPC_ID"

# Tag it
aws ec2 create-tags \
  --resources ${VPC_ID} \
  --tags Key=Name,Value=${NAME}

#2. Enable DNS
echo "→ Enabling DNS support..."
aws ec2 modify-vpc-attribute \
  --vpc-id ${VPC_ID} \
  --enable-dns-support '{"Value": true}'

aws ec2 modify-vpc-attribute \
  --vpc-id ${VPC_ID} \
  --enable-dns-hostnames '{"Value": true}'

#3. Create Subnet
echo "→ Creating Subnet..."
SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block 172.31.0.0/24 \
  --output text --query 'Subnet.SubnetId')
echo "  SUBNET_ID=$SUBNET_ID"

aws ec2 create-tags \
  --resources ${SUBNET_ID} \
  --tags Key=Name,Value=${NAME}

#4. Internet Gateway
echo "→ Creating Internet Gateway..."
INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
  --output text --query 'InternetGateway.InternetGatewayId')
echo "  INTERNET_GATEWAY_ID=$INTERNET_GATEWAY_ID"

aws ec2 create-tags \
  --resources ${INTERNET_GATEWAY_ID} \
  --tags Key=Name,Value=${NAME}

aws ec2 attach-internet-gateway \
  --internet-gateway-id ${INTERNET_GATEWAY_ID} \
  --vpc-id ${VPC_ID}

#5. Route Table
echo "→ Creating Route Table..."
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
  --vpc-id ${VPC_ID} \
  --output text --query 'RouteTable.RouteTableId')
echo "  ROUTE_TABLE_ID=$ROUTE_TABLE_ID"

aws ec2 create-tags \
  --resources ${ROUTE_TABLE_ID} \
  --tags Key=Name,Value=${NAME}

aws ec2 associate-route-table \
  --route-table-id ${ROUTE_TABLE_ID} \
  --subnet-id ${SUBNET_ID}

aws ec2 create-route \
  --route-table-id ${ROUTE_TABLE_ID} \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id ${INTERNET_GATEWAY_ID}

#6. Security Group
echo "→ Creating Security Group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --group-name ${NAME} \
  --description "Kubernetes cluster security group" \
  --vpc-id ${VPC_ID} \
  --query 'GroupId' \
  --output text)
echo "  SECURITY_GROUP_ID=$SECURITY_GROUP_ID"

aws ec2 create-tags \
  --resources ${SECURITY_GROUP_ID} \
  --tags Key=Name,Value=${NAME}

# Master port range
aws ec2 authorize-security-group-ingress \
  --group-id ${SECURITY_GROUP_ID} \
  --ip-permissions \
  IpProtocol=tcp,FromPort=2379,ToPort=2380,IpRanges='[{CidrIp=172.31.0.0/24}]'

# Worker NodePort range
aws ec2 authorize-security-group-ingress \
  --group-id ${SECURITY_GROUP_ID} \
  --ip-permissions \
  IpProtocol=tcp,FromPort=30000,ToPort=32767,IpRanges='[{CidrIp=172.31.0.0/24}]'

# Kubernetes API (public)
aws ec2 authorize-security-group-ingress \
  --group-id ${SECURITY_GROUP_ID} \
  --protocol tcp \
  --port 6443 \
  --cidr 0.0.0.0/0

# SSH (restrict in production!)
aws ec2 authorize-security-group-ingress \
  --group-id ${SECURITY_GROUP_ID} \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# ICMP
aws ec2 authorize-security-group-ingress \
  --group-id ${SECURITY_GROUP_ID} \
  --protocol icmp \
  --port -1 \
  --cidr 0.0.0.0/0

#7. Network Load Balancer
echo "→ Creating Network Load Balancer..."
LOAD_BALANCER_ARN=$(aws elbv2 create-load-balancer \
  --name ${NAME} \
  --subnets ${SUBNET_ID} \
  --scheme internet-facing \
  --type network \
  --output text --query 'LoadBalancers[].LoadBalancerArn')
echo "  LOAD_BALANCER_ARN=$LOAD_BALANCER_ARN"

#8. Target Group
echo "→ Creating Target Group..."
TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
  --name ${NAME} \
  --protocol TCP \
  --port 6443 \
  --vpc-id ${VPC_ID} \
  --target-type ip \
  --output text --query 'TargetGroups[].TargetGroupArn')
echo "  TARGET_GROUP_ARN=$TARGET_GROUP_ARN"

#9. Register Master IPs as Targets
echo "→ Registering targets..."
aws elbv2 register-targets \
  --target-group-arn ${TARGET_GROUP_ARN} \
  --targets Id=172.31.0.1{0,1,2}

#10. Create Listener on 6443
echo "→ Creating Listener..."
aws elbv2 create-listener \
  --load-balancer-arn ${LOAD_BALANCER_ARN} \
  --protocol TCP \
  --port 6443 \
  --default-actions Type=forward,TargetGroupArn=${TARGET_GROUP_ARN} \
  --output text --query 'Listeners[].ListenerArn'

#11. Get Public Address
echo "→ Getting Kubernetes Public Address..."
KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns ${LOAD_BALANCER_ARN} \
  --output text --query 'LoadBalancers[].DNSName')
echo "  KUBERNETES_PUBLIC_ADDRESS=$KUBERNETES_PUBLIC_ADDRESS"

#Save IDs for next steps
cat > "$(dirname "$0")/../../configs/network-ids.sh" <<EOF
export VPC_ID="${VPC_ID}"
export SUBNET_ID="${SUBNET_ID}"
export INTERNET_GATEWAY_ID="${INTERNET_GATEWAY_ID}"
export ROUTE_TABLE_ID="${ROUTE_TABLE_ID}"
export SECURITY_GROUP_ID="${SECURITY_GROUP_ID}"
export LOAD_BALANCER_ARN="${LOAD_BALANCER_ARN}"
export TARGET_GROUP_ARN="${TARGET_GROUP_ARN}"
export KUBERNETES_PUBLIC_ADDRESS="${KUBERNETES_PUBLIC_ADDRESS}"
EOF

echo ""
echo "✅ Network infrastructure created successfully!"
echo "   IDs saved to configs/network-ids.sh"

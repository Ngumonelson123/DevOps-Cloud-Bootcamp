#!/usr/bin/env bash
# update-inventory.sh
# Run this after 'terraform apply' to auto-fill Ansible inventory files with real IPs
# Usage: ./scripts/update-inventory.sh

set -e

TERRAFORM_DIR="$(dirname "$0")/../terraform"
ANSIBLE_DIR="$(dirname "$0")/../ansible"

echo "==> Fetching IPs from Terraform outputs..."
cd "$TERRAFORM_DIR"

JENKINS_IP=$(terraform output -raw jenkins_ip)
SONARQUBE_IP=$(terraform output -raw sonarqube_ip)
ARTIFACTORY_IP=$(terraform output -raw artifactory_ip)
NGINX_CI_IP=$(terraform output -raw nginx_ci_ip)
TOOLING_IP=$(terraform output -raw tooling_ip)
TODO_IP=$(terraform output -raw todo_ip)
NGINX_DEV_IP=$(terraform output -raw nginx_dev_ip)
DB_IP=$(terraform output -raw db_ip)

echo "Jenkins:      $JENKINS_IP"
echo "SonarQube:    $SONARQUBE_IP"
echo "Artifactory:  $ARTIFACTORY_IP"
echo "Nginx CI:     $NGINX_CI_IP"
echo "Tooling:      $TOOLING_IP"
echo "TODO:         $TODO_IP"
echo "Nginx Dev:    $NGINX_DEV_IP"
echo "DB:           $DB_IP"

echo ""
echo "==> Updating CI inventory..."
CI_INV="$ANSIBLE_DIR/inventory/ci"
sed -i "s|<JENKINS-IP>|$JENKINS_IP|g"       "$CI_INV"
sed -i "s|<SONARQUBE-IP>|$SONARQUBE_IP|g"   "$CI_INV"
sed -i "s|<ARTIFACTORY-IP>|$ARTIFACTORY_IP|g" "$CI_INV"
sed -i "s|<NGINX-CI-IP>|$NGINX_CI_IP|g"     "$CI_INV"

echo "==> Updating Dev inventory..."
DEV_INV="$ANSIBLE_DIR/inventory/dev"
sed -i "s|<TOOLING-IP>|$TOOLING_IP|g"       "$DEV_INV"
sed -i "s|<TODO-IP>|$TODO_IP|g"             "$DEV_INV"
sed -i "s|<NGINX-DEV-IP>|$NGINX_DEV_IP|g"   "$DEV_INV"
sed -i "s|<DB-IP>|$DB_IP|g"                 "$DEV_INV"

echo "==> Updating env-vars/dev.yml with DB IP..."
sed -i "s|<DB-DEV-IP>|$DB_IP|g" "$ANSIBLE_DIR/env-vars/dev.yml"

echo "==> Updating sonar-project.properties with SonarQube IP..."
SONAR_PROPS="$ANSIBLE_DIR/deploy/sonar-project.properties"
sed -i "s|<SONARQUBE-SERVER-IP>|$SONARQUBE_IP|g" "$SONAR_PROPS"

echo ""
echo "Done! Inventory files updated. Verify with:"
echo "  cat $CI_INV"
echo "  cat $DEV_INV"

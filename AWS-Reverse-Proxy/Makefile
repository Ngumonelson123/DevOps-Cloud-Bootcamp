# ============================================================
#  Makefile  –  One-command interface for the whole project
#
#  Usage:
#    make init        – terraform init
#    make plan        – terraform plan
#    make deploy      – terraform apply + sync ansible vars
#    make configure   – run ansible playbook
#    make test        – run end-to-end test suite
#    make destroy     – safe terraform destroy
#    make all         – deploy + configure + test (full pipeline)
# ============================================================

DOMAIN    ?= $(shell grep domain_name terraform.tfvars | cut -d'"' -f2)
TF_VARS   := -var="db_password=$$(grep db_password terraform.tfvars | cut -d'"' -f2)" \
             -var="db_username=$$(grep db_username terraform.tfvars | cut -d'"' -f2)"

.PHONY: init validate plan deploy sync configure verify test destroy all clean

## ── Terraform ────────────────────────────────────────────────

init:
	@echo "==> Initialising Terraform..."
	terraform init

validate: init
	@echo "==> Validating configuration..."
	terraform validate
	terraform fmt -check -recursive

plan: validate
	@echo "==> Planning infrastructure..."
	terraform plan $(TF_VARS) -out=tfplan

deploy: plan
	@echo "==> Applying infrastructure..."
	terraform apply tfplan
	@echo "==> Syncing outputs to Ansible..."
	./scripts/sync-tf-to-ansible.sh

## ── Ansible ──────────────────────────────────────────────────

sync:
	@echo "==> Syncing Terraform outputs → Ansible vars..."
	./scripts/sync-tf-to-ansible.sh

configure:
	@echo "==> Running Ansible playbook..."
	cd ansible && ansible-playbook playbooks/site.yml \
	  -i inventory/aws_ec2.yml \
	  --private-key ~/.ssh/my-keypair.pem

verify:
	@echo "==> Running Ansible verification..."
	cd ansible && ansible-playbook playbooks/verify.yml \
	  -i inventory/aws_ec2.yml \
	  --private-key ~/.ssh/my-keypair.pem

## ── Testing ──────────────────────────────────────────────────

test:
	@echo "==> Running end-to-end tests for $(DOMAIN)..."
	chmod +x scripts/test-all.sh
	./scripts/test-all.sh $(DOMAIN)

## ── Full Pipeline ────────────────────────────────────────────

all: deploy configure test
	@echo ""
	@echo "╔════════════════════════════════════════╗"
	@echo "║   Full deployment complete!            ║"
	@echo "║   WordPress: https://$(DOMAIN)         ║"
	@echo "║   Tooling:   https://tooling.$(DOMAIN) ║"
	@echo "╚════════════════════════════════════════╝"

## ── Cleanup ──────────────────────────────────────────────────

destroy:
	@echo "==> Running safe destroy..."
	chmod +x scripts/destroy-safe.sh
	./scripts/destroy-safe.sh

clean:
	rm -f tfplan
	rm -rf .terraform/
	find . -name "*.retry" -delete
	@echo "Cleaned up local Terraform files."

## ── Help ─────────────────────────────────────────────────────

help:
	@echo ""
	@echo "Available commands:"
	@echo "  make init        – Initialize Terraform"
	@echo "  make validate    – Validate + format check"
	@echo "  make plan        – Preview changes"
	@echo "  make deploy      – Apply infrastructure"
	@echo "  make configure   – Run Ansible on all servers"
	@echo "  make verify      – Verify all services are up"
	@echo "  make test        – End-to-end smoke tests"
	@echo "  make all         – Full pipeline (deploy+configure+test)"
	@echo "  make destroy     – Safely destroy all resources"
	@echo "  make clean       – Remove local Terraform files"
	@echo ""

.DEFAULT_GOAL := help

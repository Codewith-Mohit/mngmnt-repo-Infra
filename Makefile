.PHONY: help init validate plan apply destroy fmt clean setup output logs

TERRAFORM := terraform
TF_VARS ?= terraform.tfvars

help:
	@echo "Available targets:"
	@echo "  make init       - Initialize Terraform"
	@echo "  make validate   - Validate Terraform configuration"
	@echo "  make fmt        - Format Terraform files"
	@echo "  make plan       - Plan infrastructure changes"
	@echo "  make apply      - Apply infrastructure changes"
	@echo "  make destroy    - Destroy all infrastructure"
	@echo "  make clean      - Clean Terraform files (.terraform, .tfstate, etc.)"
	@echo "  make setup      - Setup: init + validate + fmt"
	@echo "  make output     - Display outputs"
	@echo "  make logs       - View Key Vault audit logs"
	@echo ""
	@echo "Example usage:"
	@echo "  make init"
	@echo "  make plan"
	@echo "  TF_VARS=prod.tfvars make apply"

init:
	@echo "🔧 Initializing Terraform..."
	$(TERRAFORM) init

validate:
	@echo "✅ Validating Terraform configuration..."
	$(TERRAFORM) validate

fmt:
	@echo "🎨 Formatting Terraform files..."
	$(TERRAFORM) fmt -recursive -write .

fmt-check:
	@echo "🔍 Checking Terraform format..."
	$(TERRAFORM) fmt -recursive -check .

plan:
	@echo "📋 Planning infrastructure changes..."
	$(TERRAFORM) plan -var-file=$(TF_VARS) -out=tfplan

plan-destroy:
	@echo "📋 Planning infrastructure destruction..."
	$(TERRAFORM) plan -var-file=$(TF_VARS) -destroy

apply: plan
	@echo "🚀 Applying infrastructure changes..."
	$(TERRAFORM) apply tfplan

apply-auto:
	@echo "🚀 Applying infrastructure changes (auto-approved)..."
	$(TERRAFORM) apply -var-file=$(TF_VARS) -auto-approve

destroy:
	@echo "⚠️  Destroying infrastructure (requires confirmation)..."
	$(TERRAFORM) destroy -var-file=$(TF_VARS)

destroy-auto:
	@echo "🔴 Destroying infrastructure (auto-approved)..."
	$(TERRAFORM) destroy -var-file=$(TF_VARS) -auto-approve

clean:
	@echo "🧹 Cleaning Terraform files..."
	rm -rf .terraform
	rm -f .terraform.lock.hcl tfplan tfplan.* terraform.tfstate*
	@echo "✅ Cleaned"

setup: init validate fmt
	@echo "✨ Setup complete!"

output:
	@echo "📊 Infrastructure outputs:"
	$(TERRAFORM) output -json

output-table:
	@echo "📊 Infrastructure outputs (table format):"
	$(TERRAFORM) output

refresh:
	@echo "🔄 Refreshing Terraform state..."
	$(TERRAFORM) refresh -var-file=$(TF_VARS)

state-list:
	@echo "📝 Current Terraform state resources:"
	$(TERRAFORM) state list

state-show:
	@echo "📝 Terraform state (JSON):"
	$(TERRAFORM) show -json | jq '.'

logs:
	@echo "📋 Key Vault usage information:"
	@echo "Note: Run 'make output' to get Key Vault name"
	@echo "Then use: az monitor activity-log list --resource-group <RG> --query-examples"

console:
	@echo "🔍 Opening Terraform console..."
	$(TERRAFORM) console

upgrade:
	@echo "⬆️  Upgrading Terraform providers..."
	$(TERRAFORM) init -upgrade

taint-all:
	@echo "⚠️  Tainting all resources for recreate..."
	@for resource in $$($(TERRAFORM) state list); do \
		echo "Tainting: $$resource"; \
		$(TERRAFORM) taint "$$resource"; \
	done

untaint-all:
	@echo "✅ Removing taint from all resources..."
	@for resource in $$($(TERRAFORM) state list); do \
		echo "Untainting: $$resource"; \
		$(TERRAFORM) untaint "$$resource"; \
	done

version:
	@echo "Terraform version:"
	$(TERRAFORM) version
	@echo ""
	@echo "Azure CLI version:"
	az --version

lint:
	@echo "🔍 Running Terraform linting..."
	$(TERRAFORM) fmt -recursive -check .
	@if command -v tfsec > /dev/null; then \
		echo "🔐 Running security check (tfsec)..."; \
		tfsec .; \
	else \
		echo "⚠️  tfsec not installed. Skipping security check."; \
		echo "   Install with: brew install tfsec (macOS) or https://github.com/aquasecurity/tfsec"; \
	fi

.DEFAULT_GOAL := help

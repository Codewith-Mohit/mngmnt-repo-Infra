#!/bin/bash
# Initialize Terraform and validate configuration

set -e

echo "🔍 Validating Terraform configuration..."
terraform fmt -check -recursive . || {
    echo "⚠️  Terraform formatting issues found. Running terraform fmt..."
    terraform fmt -recursive .
}

echo "✅ Initializing Terraform..."
terraform init

echo "✅ Validating configuration..."
terraform validate

echo "✅ Running security linting (tfsec)..."
if command -v tfsec &> /dev/null; then
    tfsec . || true
else
    echo "⚠️  tfsec not installed. Skipping security scan."
fi

echo "✅ Planning infrastructure changes..."
terraform plan -out=tfplan

echo ""
echo "📋 Plan Summary:"
echo "==============="
terraform show -json tfplan | jq '.resource_changes[] | select(.change.actions != ["no-op"]) | {address: .address, actions: .change.actions}' || true

echo ""
echo "✨ Next step: Review the plan and run 'terraform apply tfplan' to deploy"

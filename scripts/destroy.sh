#!/bin/bash
# Destroy all resources created by Terraform

set -e

echo "⚠️  WARNING: This will destroy all infrastructure!"
echo "Resources to be destroyed:"
terraform plan -destroy

read -p "Are you sure you want to proceed? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "❌ Destruction cancelled."
    exit 1
fi

echo "🔴 Destroying infrastructure..."
terraform destroy -auto-approve

echo "✅ Infrastructure destroyed successfully."

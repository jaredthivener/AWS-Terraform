.PHONY: help init plan apply destroy validate fmt clean kubectl-config

# Default target
help:
	@echo "EKS Free Tier Terraform Commands"
	@echo "================================="
	@echo "init          - Initialize Terraform"
	@echo "validate      - Validate Terraform configuration"
	@echo "fmt           - Format Terraform files"
	@echo "plan          - Create Terraform execution plan"
	@echo "apply         - Apply Terraform configuration"
	@echo "destroy       - Destroy Terraform infrastructure"
	@echo "kubectl-config - Configure kubectl for the cluster"
	@echo "clean         - Clean Terraform state files"
	@echo "check-costs   - Check current AWS costs"

# Initialize Terraform
init:
	terraform init

# Validate configuration
validate: fmt
	terraform validate

# Format Terraform files
fmt:
	terraform fmt -recursive

# Create execution plan
plan: validate
	terraform plan

# Apply configuration
apply: validate
	terraform apply

# Destroy infrastructure
destroy:
	terraform destroy

# Configure kubectl
kubectl-config:
	@echo "Configuring kubectl..."
	@CLUSTER_NAME=$$(terraform output -raw cluster_name 2>/dev/null || echo "eks-free-tier-demo"); \
	REGION=$$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1"); \
	aws eks update-kubeconfig --region $$REGION --name $$CLUSTER_NAME

# Clean up state files (use with caution)
clean:
	rm -f terraform.tfstate*
	rm -f .terraform.lock.hcl
	rm -rf .terraform/

# Check costs
check-costs:
	@echo "Checking current month costs..."
	@START_DATE=$$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d); \
	END_DATE=$$(date +%Y-%m-%d); \
	aws ce get-cost-and-usage \
		--time-period Start=$$START_DATE,End=$$END_DATE \
		--granularity MONTHLY \
		--metrics BlendedCost \
		--group-by Type=DIMENSION,Key=SERVICE \
		--query 'ResultsByTime[0].Groups[?Metrics.BlendedCost.Amount>`0`].[Keys[0],Metrics.BlendedCost.Amount]' \
		--output table

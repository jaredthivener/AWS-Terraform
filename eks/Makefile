.PHONY: help init plan apply destroy validate fmt clean kubectl-config

# Default target
help:
	@echo "EKS Free Tier Terraform Commands"
	@echo "================================="
	@echo "init               - Initialize Terraform"
	@echo "validate           - Validate Terraform configuration"
	@echo "fmt                - Format Terraform files"
	@echo "plan               - Create Terraform execution plan"
	@echo "apply              - Apply Terraform configuration"
	@echo "destroy            - Destroy Terraform infrastructure"
	@echo "kubectl-config     - Configure kubectl for the cluster"
	@echo "clean              - Clean Terraform state files"
	@echo "check-costs        - Check current AWS costs (requires Cost Explorer)"
	@echo "check-costs-alt    - Alternative cost checking methods"
	@echo "check-free-tier    - Check free tier resource usage"
	@echo "check-expensive-resources - Check for resources that cost money"

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
	@echo "Note: This requires AWS Cost Explorer permissions (ce:GetCostAndUsage)"
	@START_DATE=$$(date +%Y-%m-01); \
	END_DATE=$$(date +%Y-%m-%d); \
	echo "Checking costs from $$START_DATE to $$END_DATE"; \
	aws ce get-cost-and-usage \
		--time-period Start=$$START_DATE,End=$$END_DATE \
		--granularity MONTHLY \
		--metrics BlendedCost \
		--group-by Type=DIMENSION,Key=SERVICE \
		--query 'ResultsByTime[0].Groups[?Metrics.BlendedCost.Amount>`0`].[Keys[0],Metrics.BlendedCost.Amount]' \
		--output table || echo "Error: Cost Explorer access denied. You may need to enable Cost Explorer or add permissions."

# Check costs (alternative method using billing alerts if available)
check-costs-alt:
	@echo "Alternative cost checking methods:"
	@echo "1. Check current resource usage that might incur costs..."
	@echo "   EC2 instances:"
	@aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,InstanceType,State.Name]' --output table || echo "   No EC2 access or no running instances"
	@echo "   EKS clusters:"
	@aws eks list-clusters --query 'clusters' --output table || echo "   No EKS access or no clusters"
	@echo "   NAT Gateways:"
	@aws ec2 describe-nat-gateways --query 'NatGateways[?State==`available`].[NatGatewayId,State]' --output table || echo "   No NAT gateways or no access"
	@echo "   Load Balancers:"
	@aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,Type,State.Code]' --output table || echo "   No load balancers or no access"
	@echo ""
	@echo "2. To enable Cost Explorer:"
	@echo "   - Go to AWS Console > Billing > Cost Explorer"
	@echo "   - Enable Cost Explorer (may take 24 hours to activate)"
	@echo "   - Add IAM permissions: ce:GetCostAndUsage, ce:GetUsageReport"

# Monitor free tier usage
check-free-tier:
	@echo "Checking free tier eligible resources..."
	@echo "Free tier limits to watch:"
	@echo "- EC2: 750 hours/month of t2.micro or t3.micro"
	@echo "- EKS: \$$0.10 per hour per cluster (no free tier)"
	@echo "- NAT Gateway: \$$0.045 per hour + data processing costs"
	@echo ""
	@echo "Current resources that may consume free tier:"
	@aws ec2 describe-instances \
		--filters "Name=instance-state-name,Values=running" \
		--query 'Reservations[].Instances[?InstanceType==`t2.micro` || InstanceType==`t3.micro` || InstanceType==`t3.nano`].[InstanceId,InstanceType,LaunchTime]' \
		--output table || echo "No t2.micro/t3.micro/t3.nano instances running"

# Check resources that cost money
check-expensive-resources:
	@echo "Checking for resources that typically cost money..."
	@echo "EKS Clusters (\$$0.10/hour each):"
	@aws eks list-clusters --output table || echo "No EKS clusters or access denied"
	@echo ""
	@echo "NAT Gateways (\$$0.045/hour each + data processing):"
	@aws ec2 describe-nat-gateways --filter "Name=state,Values=available" --query 'NatGateways[*].[NatGatewayId,VpcId,SubnetId,State]' --output table || echo "No NAT gateways or access denied"
	@echo ""
	@echo "Load Balancers:"
	@aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,Type,Scheme,CreatedTime]' --output table || echo "No load balancers or access denied"
	@echo ""
	@echo "Non-free tier EC2 instances:"
	@aws ec2 describe-instances \
		--filters "Name=instance-state-name,Values=running" \
		--query 'Reservations[].Instances[?InstanceType!=`t2.micro` && InstanceType!=`t3.micro` && InstanceType!=`t3.nano`].[InstanceId,InstanceType,LaunchTime]' \
		--output table || echo "No non-free-tier instances running"

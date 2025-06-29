locals {
  # AWS Account ID handling
  aws_account_id = var.aws_account_id != null ? var.aws_account_id : data.aws_caller_identity.current.account_id

  # Common tags applied to all resources
  common_tags = {
    Project     = "eks-free-tier"
    Environment = "dev"
    Owner       = var.owner_name
    ManagedBy   = "terraform"
    CostCenter  = "development"
  }

  # Karpenter discovery tags
  karpenter_discovery_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  # Merged tags for VPC and EKS resources
  vpc_tags = merge(local.common_tags, local.karpenter_discovery_tags)
  eks_tags = merge(local.common_tags, local.karpenter_discovery_tags)

  # Free tier optimized settings
  free_tier_config = {
    max_nodes        = 3
    max_cpu_cores    = 6
    max_memory_gb    = 12
    spot_percentage  = 80 # Use 80% spot instances for cost savings
    node_volume_size = 20 # Minimum EBS volume size
  }
}

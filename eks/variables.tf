# Variables for EKS Free Tier robust learning environment

variable "aws_region" {
  description = "AWS region to deploy EKS cluster. Default is us-west-2 for free tier."
  type        = string
  default     = "us-east-1"
}

variable "owner_name" {
  description = "Owner or responsible person for this environment. Used for tagging."
  type        = string
  default     = "changeme"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "eks-free-tier-demo"
}

variable "enable_cluster_logging" {
  description = "Enable EKS cluster logging (can increase costs)"
  type        = bool
  default     = false
}

variable "node_instance_types" {
  description = "Instance types for Karpenter nodes (free tier optimized)"
  type        = list(string)
  default     = ["t3.micro", "t3.small", "t3.medium"]
}

# Data sources
data "aws_caller_identity" "current" {}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "~> 5.0"
  name                 = "eks-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets       = ["10.0.3.0/24", "10.0.4.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project                  = "eks-free-tier"
    Environment              = "dev"
    Owner                    = var.owner_name
    "karpenter.sh/discovery" = var.cluster_name
  }
  vpc_tags = {
    Project                  = "eks-free-tier"
    Environment              = "dev"
    Owner                    = var.owner_name
    "karpenter.sh/discovery" = var.cluster_name
  }
  private_subnet_tags = {
    "karpenter.sh/discovery"          = var.cluster_name
    "kubernetes.io/role/internal-elb" = "1"
  }
  public_subnet_tags = {
    "karpenter.sh/discovery" = var.cluster_name
    "kubernetes.io/role/elb" = "1"
  }
  # Outbound connectivity for private subnets (NAT Gateway, Free Tier: single NAT)
  enable_nat_gateway      = true
  single_nat_gateway      = true
  map_public_ip_on_launch = true
}

module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "20.37.1"
  cluster_name                             = var.cluster_name
  cluster_version                          = "1.33"
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
    coredns                = {}
    aws-ebs-csi-driver     = {}
  }

  # Enable IRSA for service accounts
  enable_irsa = true

  # EKS Managed Node Groups for initial workloads
  eks_managed_node_groups = {
    initial = {
      name           = "initial-node-group"
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Use private subnets for security
      subnet_ids = module.vpc.private_subnets

      labels = {
        Environment = "dev"
        NodeType    = "initial"
      }

      taints = []

      tags = {
        Environment = "dev"
        NodeType    = "initial"
      }
    }
  }

  tags = {
    Project                  = "eks-free-tier"
    Environment              = "dev"
    Owner                    = var.owner_name
    "karpenter.sh/discovery" = var.cluster_name
  }
  cluster_tags = {
    Project                  = "eks-free-tier"
    Environment              = "dev"
    Owner                    = var.owner_name
    "karpenter.sh/discovery" = var.cluster_name
  }
}

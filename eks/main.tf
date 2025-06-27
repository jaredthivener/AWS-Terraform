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
    "karpenter.sh/discovery" = var.cluster_name
  }
  public_subnet_tags = {
    "karpenter.sh/discovery" = var.cluster_name
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
  cluster_version                          = "1.31"
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
  }

  fargate_profiles = {
    example = {
      name      = "example"
      selectors = [{ namespace = "default" }]
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

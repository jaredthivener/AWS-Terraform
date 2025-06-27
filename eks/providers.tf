terraform {
  required_version = ">= 1.3.2"
  required_providers {
    aws        = { source = "hashicorp/aws", version = ">= 5.95.0, < 6.0.0" }
    helm       = { source = "hashicorp/helm", version = ">= 2.7, < 3.0.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.20" }
    kubectl    = { source = "alekc/kubectl", version = ">= 2.1.3" }
  }
}

provider "aws" {
  region = var.aws_region
  
  # Remove hardcoded role ARN - use environment variables or AWS CLI profile instead
  # assume_role {
  #   role_arn     = "arn:aws:iam::222928549187:role/AdminAssumeRole"
  #   session_name = "TerraformSession"
  # }
  
  default_tags {
    tags = {
      Project     = "eks-free-tier"
      Environment = "dev"
      Owner       = var.owner_name
      ManagedBy   = "terraform"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

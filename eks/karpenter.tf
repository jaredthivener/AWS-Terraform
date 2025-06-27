# IAM Role for Karpenter via EKS module
module "karpenter" {
  source                 = "terraform-aws-modules/eks/aws//modules/karpenter"
  cluster_name           = module.eks.cluster_name
  enable_irsa            = true
  namespace              = "karpenter"
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn
}

# Karpenter Helm install
# Uses default providers from providers.tf

resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "https://charts.karpenter.sh"
  chart            = "karpenter"
  version          = "1.5.0"
  namespace        = "karpenter"
  create_namespace = true

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.iam_role_arn
  }
  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "clusterEndpoint"
    value = module.eks.cluster_endpoint
  }
  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = module.karpenter.node_iam_role_name
  }
}

# EC2NodeClass & NodePool CRDs for Karpenter v0.16+
resource "kubectl_manifest" "karpenter_ec2nodeclass" {
  depends_on = [helm_release.karpenter]
  yaml_body = templatefile("${path.module}/karpenter-ec2nodeclass.yaml", {
    cluster_name = module.eks.cluster_name
  })
}

resource "kubectl_manifest" "karpenter_nodepool" {
  depends_on = [helm_release.karpenter, kubectl_manifest.karpenter_ec2nodeclass]
  yaml_body  = file("${path.module}/karpenter-nodepool.yaml")
}

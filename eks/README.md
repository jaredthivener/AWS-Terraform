# EKS Free Tier with Karpenter

This Terraform configuration creates a cost-optimized EKS cluster with Karpenter autoscaling, designed for free tier usage.

## Architecture

- **EKS Cluster**: Running on AWS Free Tier with managed node groups and Karpenter autoscaling
- **Karpenter**: Latest v1.5.1 for efficient node provisioning and cost optimization
- **AWS Load Balancer Controller**: Proper Helm installation with IRSA for ingress management
- **VPC**: Multi-AZ setup with public/private subnets and proper tagging for ALB
- **Security**: Encrypted EBS volumes, secure instance metadata, minimal IAM permissions

## Features

- ✅ **Cost Optimized**: Single NAT Gateway, spot instances, resource limits
- ✅ **Latest APIs**: Karpenter v1.5.1 (EC2NodeClass + NodePool), EKS 1.31
- ✅ **Load Balancing**: AWS Load Balancer Controller with proper IRSA setup
- ✅ **Security**: Encrypted storage, secure metadata, proper RBAC
- ✅ **Monitoring**: CloudWatch logs (optional), comprehensive outputs
- ✅ **Free Tier**: Designed for t3.micro/small instances with managed node groups

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.3.2
3. kubectl (for post-deployment management)

## Quick Start

1. **Clone and configure**:
   ```bash
   git clone <this-repo>
   cd eks-free-tier
   ```

2. **Set variables** (optional):
   ```bash
   export TF_VAR_aws_region="us-east-1"
   export TF_VAR_cluster_name="my-eks-cluster"
   export TF_VAR_owner_name="your-name"
   ```

3. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configure kubectl**:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name eks-free-tier-demo
   ```

## Configuration

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `cluster_name` | EKS cluster name | `eks-free-tier-demo` |
| `owner_name` | Owner tag value | `changeme` |
| `enable_cluster_logging` | Enable CloudWatch logs | `false` |
| `node_instance_types` | Instance types for Karpenter | `["t3.micro", "t3.small", "t3.medium"]` |

### Cost Optimization Features

- **Single NAT Gateway**: Reduces NAT costs
- **Spot Instances**: 80% spot instance preference
- **Resource Limits**: CPU and memory caps
- **Free Tier Instances**: t3.micro/small focus
- **Minimal Logging**: Disabled by default

## Recent Improvements

- ✅ **Updated to AWS Load Balancer Controller v2.13.3**: Latest version with security updates
- ✅ **Proper IRSA Configuration**: Service account managed externally with correct permissions
- ✅ **Resource Limits**: CPU and memory limits configured for better resource management
- ✅ **Target Type Optimization**: Set to `ip` for better performance with VPC CNI
- ✅ **Integrated CRDs Management**: CRDs installed automatically via Terraform (no manual steps)

## Usage Examples

### Deploy a test workload:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      tolerations:
      - key: karpenter.sh/spot
        operator: Exists
        effect: NoSchedule
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

### Check Karpenter status:

```bash
kubectl get nodes -l node-type=karpenter-managed
kubectl get nodeclaims
kubectl get nodepools
```

## Monitoring

### View cluster info:
```bash
kubectl cluster-info
kubectl get nodes -o wide
```

### Check Karpenter logs:
```bash
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter
```

### Monitor costs:
```bash
# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:karpenter.sh/discovery,Values=eks-free-tier-demo"

# Monitor spend
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

## Troubleshooting

### Common Issues

1. **Pods pending**: Check node provisioning
   ```bash
   kubectl describe pod <pod-name>
   kubectl get events --sort-by='.lastTimestamp'
   ```

2. **Karpenter not working**: Check logs and configuration
   ```bash
   kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter
   kubectl get ec2nodeclass default -o yaml
   kubectl get nodepool default -o yaml
   ```

3. **High costs**: Review instance types and spot usage
   ```bash
   kubectl get nodes -l karpenter.sh/capacity-type=spot
   ```

## Security Considerations

- Remove the hardcoded IAM role from `providers.tf`
- Enable cluster logging for production use
- Review and restrict CIDR blocks for endpoint access
- Implement proper backup strategies

## Cleanup

```bash
# Delete workloads first
kubectl delete all --all

# Wait for nodes to terminate
kubectl get nodes --watch

# Destroy infrastructure
terraform destroy
```

## Contributing

1. Test changes with `terraform plan`
2. Ensure free tier compatibility
3. Update documentation
4. Submit PR with clear description

## License

MIT License - see LICENSE file for details.

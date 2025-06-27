# AWS Infrastructure with Terraform

A comprehensive Terraform configuration for deploying production-ready AWS infrastructure including EKS clusters with Karpenter autoscaling and RDS database clusters.

## 🏗️ Architecture Overview

This repository contains two main infrastructure components:

- **EKS Cluster** - Production-ready Kubernetes cluster with Karpenter autoscaling
- **RDS Clusters** - Multi-database Aurora clusters with encryption and high availability

## 📁 Repository Structure

```
AWS-Terraform/
├── eks/                    # EKS cluster with Karpenter
│   ├── main.tf            # VPC and EKS cluster configuration
│   ├── karpenter.tf       # Karpenter autoscaler setup
│   ├── providers.tf       # Provider configurations
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values
│   ├── locals.tf          # Local values and tags
│   ├── Makefile          # Automation commands
│   └── README.md         # EKS-specific documentation
├── rds/                   # RDS Aurora clusters
│   ├── main.tf           # Database clusters and encryption
│   ├── var.tf            # RDS variables
│   └── README.md         # RDS-specific documentation
└── README.md             # This file
```

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.3.2
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for EKS management

### Environment Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd AWS-Terraform
   ```

2. **Configure AWS credentials**:
   ```bash
   aws configure
   # or use environment variables
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

## 🎯 Deployment Options

### Option 1: EKS Cluster Only

Deploy a cost-optimized Kubernetes cluster with Karpenter autoscaling:

```bash
cd eks/
make init
make plan
make apply
```

**Features:**
- ✅ Multi-AZ VPC with public/private subnets
- ✅ EKS cluster with Fargate profiles
- ✅ Karpenter for efficient node provisioning
- ✅ Cost-optimized for AWS Free Tier
- ✅ Spot instance support (80% spot preference)
- ✅ Encrypted EBS volumes

### Option 2: RDS Clusters Only

Deploy multiple Aurora database clusters:

```bash
cd rds/
terraform init
terraform plan
terraform apply
```

**Features:**
- ✅ Multiple Aurora clusters (MySQL & PostgreSQL)
- ✅ Customer-managed KMS encryption
- ✅ Automated backups and point-in-time recovery
- ✅ Performance Insights enabled
- ✅ Secrets Manager integration
- ✅ High availability across AZs

### Option 3: Complete Infrastructure

Deploy both EKS and RDS (recommended for production):

```bash
# Deploy EKS first
cd eks/
make apply

# Get VPC outputs for RDS
terraform output vpc_id
terraform output private_subnet_ids

# Update RDS variables with EKS VPC subnets
cd ../rds/
# Edit var.tf with subnet IDs from EKS output
terraform init
terraform apply
```

## 🔧 Configuration

### EKS Configuration

Key variables in [`eks/variables.tf`](eks/variables.tf):

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `cluster_name` | EKS cluster name | `eks-free-tier-demo` |
| `owner_name` | Resource owner tag | `changeme` |
| `node_instance_types` | Karpenter instance types | `["t3.micro", "t3.small", "t3.medium"]` |

### RDS Configuration

Key variables in [`rds/var.tf`](rds/var.tf):

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | AWS region | `us-east-1` |
| `subnet_ids` | Private subnet IDs | `["subnet-xxx", "subnet-yyy"]` |
| `master_username` | Database admin user | `admin` |
| `deletion_protection` | Prevent accidental deletion | `true` |

## 💰 Cost Optimization

### EKS Cost Features
- **Single NAT Gateway**: Reduces network costs
- **Spot Instances**: 80% spot instance preference
- **Resource Limits**: CPU/memory caps in [`locals.tf`](eks/locals.tf)
- **Free Tier Instances**: Focused on t3.micro/small
- **Optional Logging**: CloudWatch logs disabled by default

### RDS Cost Considerations
- **Right-sizing**: Choose appropriate instance types
- **Backup Retention**: Configurable retention period
- **Multi-AZ**: Can be disabled for development environments

## 🛠️ Management Commands

### EKS Management

```bash
cd eks/

# Initialize and validate
make init
make validate

# Plan and apply changes
make plan
make apply

# Configure kubectl
make kubectl-config

# Check costs
make check-costs

# Cleanup
make destroy
```

### RDS Management

```bash
cd rds/

# Standard Terraform workflow
terraform init
terraform plan
terraform apply
terraform destroy
```

## 📊 Monitoring and Troubleshooting

### EKS Monitoring

```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes -o wide

# Monitor Karpenter
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter
kubectl get nodeclaims
kubectl get nodepools

# Check workload status
kubectl get pods --all-namespaces
kubectl top nodes
```

### RDS Monitoring

```bash
# Check cluster status
aws rds describe-db-clusters --region us-east-1

# View Performance Insights
aws rds describe-db-instances --region us-east-1

# Monitor costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

## 🔒 Security Best Practices

### Implemented Security Features

- ✅ **Encryption at rest**: KMS encryption for EBS volumes and RDS
- ✅ **Encryption in transit**: TLS for all communications
- ✅ **IAM roles**: Least-privilege access with IRSA
- ✅ **Private subnets**: Database and worker nodes in private subnets
- ✅ **Secrets management**: AWS Secrets Manager for database passwords
- ✅ **Network security**: Security groups and NACLs

### Security Checklist

- [ ] Remove hardcoded values from [`eks/providers.tf`](eks/providers.tf)
- [ ] Update default subnet IDs in [`rds/var.tf`](rds/var.tf)
- [ ] Enable CloudWatch logging for production
- [ ] Implement proper backup strategies
- [ ] Review and restrict CIDR blocks
- [ ] Enable GuardDuty and Security Hub

## 🧪 Testing

### Deploy Test Workload

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  namespace: default
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
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: test-app-service
spec:
  selector:
    app: test-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

### Database Connection Test

```bash
# Get database endpoints
cd rds/
terraform output database_endpoints

# Connect to PostgreSQL cluster
psql -h <endpoint> -U admin -d db2

# Connect to MySQL cluster
mysql -h <endpoint> -u admin -p db1
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Terraform Deploy
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [eks, rds]
    steps:
    - uses: actions/checkout@v3
    - uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.3.2
    - name: Terraform Init
      run: |
        cd ${{ matrix.environment }}
        terraform init
    - name: Terraform Plan
      run: |
        cd ${{ matrix.environment }}
        terraform plan
```

## 🚨 Troubleshooting

### Common Issues

1. **EKS nodes not joining**: Check security groups and IAM roles
2. **Karpenter not scaling**: Verify node pool configuration and resource requests
3. **RDS connection timeout**: Check security groups and subnet routing
4. **High AWS costs**: Review instance types and enable cost monitoring

### Getting Help

- Check the respective README files in [`eks/`](eks/README.md) and [`rds/`](rds/README.md)
- Review Terraform state: `terraform show`
- Enable debug logging: `TF_LOG=DEBUG terraform apply`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Test your changes: `terraform plan`
4. Commit your changes: `git commit -am 'Add feature'`
5. Push to the branch: `git push origin feature-name`
6. Submit a pull request

### Development Guidelines

- Test all changes with `terraform plan`
- Ensure free tier compatibility for EKS
- Update documentation for any new features
- Follow Terraform best practices
- Include cost impact analysis

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Karpenter Documentation](https://karpenter.sh/)
- [Aurora User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/)
- [AWS Free Tier](https://aws.amazon.com/free/)

---

⭐ **Star this repository if you find it useful!**
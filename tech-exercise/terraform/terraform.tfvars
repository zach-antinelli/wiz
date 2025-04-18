region = "us-west-2"

# VPC
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-west-2a", "us-west-2b", "us-west-2c"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# Cluster
cluster_name             = "eks-dev"
kubernetes_version       = "1.32"
node_instance_type       = "t4g.small" # Must be Graviton compatible instance type
node_group_capacity_type = "ON_DEMAND" # Can be "SPOT" or "ON_DEMAND"
node_volume_size         = 20
node_group_min_size      = 1
node_group_max_size      = 3
node_group_desired_size  = 1

tags = {
  Environment = "dev"
  Managed_by  = "Terraform"
  Project     = "Wiz Tech Exercise"
  Owner       = "zantinelli"
}

# S3 Bucket
bucket_name = "zantinelli-wiz-tech-exercise"

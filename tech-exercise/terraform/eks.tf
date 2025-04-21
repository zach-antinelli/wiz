module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.35"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  create_kms_key = true

  cluster_encryption_config = {
    resources = ["secrets"]
  }

  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0", var.management_ip_cidr]

  cluster_security_group_id   = aws_security_group.cluster_sg.id
  cluster_security_group_name = "${var.cluster_name}-cluster-sg"
  cluster_security_group_tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cluster-sg"
    }
  )

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  cloudwatch_log_group_retention_in_days = 7

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true
  enable_security_groups_for_pods          = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  eks_managed_node_groups = {
    "${var.cluster_name}-node-group" = {
      ami_type      = "AL2023_x86_64_STANDARD"
      min_size      = var.node_group_min_size
      max_size      = var.node_group_max_size
      desired_size  = var.node_group_desired_size
      instance_type = "m5.large"
      capacity_type = var.node_group_capacity_type

      subnet_ids         = module.vpc.private_subnets
      security_group_ids = [aws_security_group.worker_sg.id]

      tags = var.tags

      create_launch_template = true
      launch_template_name   = "${var.cluster_name}-node-launch-template"

      create_iam_role = true
      iam_role_name   = "${var.cluster_name}-node-role"

      iam_role_additional_policies = {
        AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.node_volume_size
            volume_type           = "gp3"
            encrypted             = false
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "enabled"
      }
    }
  }

  tags = var.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller = true

  aws_load_balancer_controller = {
    cluster_name             = module.eks.cluster_name
    service_account_role_arn = aws_iam_role.load_balancer_controller_role.arn
  }

  eks_addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI           = "true"
          ENABLE_PREFIX_DELEGATION = "true"
        }
      })
    }
  }

  tags = var.tags
}


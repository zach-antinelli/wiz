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

  # Generating a node group per AZ
  eks_managed_node_groups = merge(
    {
      for az_suffix in ["2a", "2b", "2c"] :
      "${var.cluster_name}-node-group-${az_suffix}" => {
        ami_type       = "AL2023_x86_64_STANDARD"
        min_size       = var.nodes_per_az
        max_size       = var.nodes_per_az
        desired_size   = var.nodes_per_az
        instance_types = ["m5.large"]
        capacity_type  = var.node_group_capacity_type

        subnet_ids = [module.vpc.private_subnets[index(["2a", "2b", "2c"], az_suffix)]]

        additional_tags = {
          "k8s.amazonaws.com/eniConfig" = "us-west-${az_suffix}"
        }

        security_group_ids  = [aws_security_group.worker_sg.id]
        security_group_name = "${var.cluster_name}-worker-sg"
        security_group_tags = merge(
          var.tags,
          {
            Name = "${var.cluster_name}-worker-sg"
          }
        )

        create_iam_role = true
        iam_role_name   = "${var.cluster_name}-node-group-role-us-west-${az_suffix}"

        iam_role_additional_policies = {
          AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
          AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
          AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
          AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
          AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
          SecurityGroupForPodsPolicy         = aws_iam_policy.security_groups_for_pods.arn
        }

        create_launch_template = true
        launch_template_name   = "${var.cluster_name}-node-lt-us-west-${az_suffix}"

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
  )

  tags = var.tags
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

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
          ENABLE_POD_ENI                     = "true"
          ENABLE_PREFIX_DELEGATION           = "true"
          AWS_VPC_K8S_CNI_EXTERNALSNAT       = "true"
          AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
        }
      })
    }
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    cluster_name             = module.eks.cluster_name
    service_account_role_arn = aws_iam_role.load_balancer_controller_role.arn
  }

  tags = var.tags
}

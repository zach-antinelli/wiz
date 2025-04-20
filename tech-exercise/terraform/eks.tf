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
  cluster_security_group_tags = var.tags

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  cloudwatch_log_group_retention_in_days = 7

  eks_managed_node_groups = {
    "${var.cluster_name}-node-group" = {
      ami_type       = "AL2023_x86_64_STANDARD"
      min_size       = var.node_group_min_size
      max_size       = var.node_group_max_size
      desired_size   = var.node_group_desired_size
      instance_types = [var.node_instance_type]
      capacity_type  = var.node_group_capacity_type

      subnet_ids = module.vpc.private_subnets

      security_group_ids  = [aws_security_group.worker_sg.id]
      security_group_name = "${var.cluster_name}-worker-sg"
      security_group_tags = var.tags

      create_iam_role = true
      iam_role_name   = "${var.cluster_name}-node-group-role"

      iam_role_additional_policies = {
        AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        SecurityGroupForPodsPolicy         = aws_iam_policy.security_groups_for_pods.arn
      }

      create_launch_template = true
      launch_template_name   = "${var.cluster_name}-lt"

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

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

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
    aws-ebs-csi-driver = {
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
          ENABLE_POD_ENI               = "true"
          AWS_VPC_K8S_CNI_EXTERNALSNAT = "true"
          ENABLE_PREFIX_DELEGATION     = "true"
          ENABLE_NETWORK_POLICY        = "true"
          ENABLE_POD_SECURITY_GROUPS   = "true"
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

# Remove broad 0.0.0.0 rule for GitHub runner on cluster SG after provisioning
resource "null_resource" "update_cluster_security" {
  depends_on = [
    module.eks,
    module.eks_blueprints_addons
  ]

  triggers = {
    cluster_name = module.eks.cluster_name
    sg_id        = aws_security_group.cluster_sg.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for cluster to be fully available
      echo "Waiting for EKS cluster to be fully available..."
      aws eks wait cluster-active --name ${var.cluster_name}

      echo "Updating security group to restrict to management IP only..."

      # Remove the temporary public access rule
      RULES=$(aws ec2 describe-security-group-rules \
        --filter "Name=group-id,Values=${aws_security_group.cluster_sg.id}" \
        --query "SecurityGroupRules[?CidrIpv4=='0.0.0.0/0' && FromPort==443 && ToPort==443 && IpProtocol=='tcp'].SecurityGroupRuleId" \
        --output text)

      if [ ! -z "$RULES" ]; then
        for RULE_ID in $RULES; do
          aws ec2 revoke-security-group-ingress \
            --group-id ${aws_security_group.cluster_sg.id} \
            --security-group-rule-ids $RULE_ID
          echo "Removed temporary public access rule $RULE_ID"
        done
      fi

      # Add management IP access rule
      aws ec2 authorize-security-group-ingress \
        --group-id ${aws_security_group.cluster_sg.id} \
        --ip-protocol tcp \
        --from-port 443 \
        --to-port 443 \
        --cidr ${var.management_ip_cidr} \
        --description "Management IP access to K8s API"

      echo "Security group updated to restrict access to management IP only"
    EOT
  }
}

# Remove broad 0.0.0.0/0 rule from cluster endpoint access CIDRs after provisioning
resource "null_resource" "update_cluster_endpoint_access" {
  depends_on = [
    module.eks,
    module.eks_blueprints_addons
  ]

  triggers = {
    cluster_name = module.eks.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for cluster to be fully available
      echo "Waiting for EKS cluster to be fully available..."
      aws eks wait cluster-active --name ${var.cluster_name}

      echo "Updating cluster endpoint access to restrict to management IP only..."

      # Get current access CIDRs
      CURRENT_CIDRS=$(aws eks describe-cluster --name ${var.cluster_name} \
        --query "cluster.resourcesVpcConfig.publicAccessCidrs" --output json)

      echo "Current access CIDRs: $CURRENT_CIDRS"

      # Check if 0.0.0.0/0 is in the CIDRs
      if echo "$CURRENT_CIDRS" | grep -q "0.0.0.0/0"; then
        echo "Removing 0.0.0.0/0 from access CIDRs..."

        # Update cluster to use only management IP
        aws eks update-cluster-config \
          --name ${var.cluster_name} \
          --resources-vpc-config endpointPublicAccess=true,publicAccessCidrs=${var.management_ip_cidr}

        # Wait for update to complete
        echo "Waiting for cluster update to complete..."
        aws eks wait cluster-active --name ${var.cluster_name}

        echo "Cluster endpoint access restricted to management IP only"
      else
        echo "0.0.0.0/0 not found in access CIDRs, no changes needed"
      fi
    EOT
  }
}

data "aws_iam_policy_document" "load_balancer_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.eks.cluster_oidc_issuer_url}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_policy" "load_balancer_controller_policy" {
  name        = "${var.cluster_name}-load-balancer-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.aws_iam_policy_document.load_balancer_controller_policy.json
}

data "aws_iam_policy_document" "load_balancer_controller_policy" {
  statement {
    actions = [
      "elasticloadbalancing:*",
      "ec2:Describe*",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "iam:CreateServiceLinkedRole",
      "cognito-idp:DescribeUserPoolClient",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "load_balancer_controller_role" {
  name               = "${var.cluster_name}-load-balancer-controller-role"
  assume_role_policy = data.aws_iam_policy_document.load_balancer_controller_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller_policy_attachment" {
  role       = aws_iam_role.load_balancer_controller_role.name
  policy_arn = aws_iam_policy.load_balancer_controller_policy.arn
}

data "aws_iam_policy_document" "db_vm_assume_role_policy" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "db_vm_instance_role" {
  name               = "${var.cluster_name}-db-vm-role"
  assume_role_policy = data.aws_iam_policy_document.db_vm_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "administrator" {
  role       = aws_iam_role.db_vm_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "db_vm_instance_profile" {
  name = "${var.cluster_name}-db-vm-instance-profile"
  role = aws_iam_role.db_vm_instance_role.name
}

resource "aws_iam_policy" "security_groups_for_pods" {
  name        = "${var.cluster_name}-sg-for-pods"
  description = "IAM policy allowing EKS to manage security groups for pods"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AssignPrivateIpAddresses",
          "ec2:AttachNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:CreateTags",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

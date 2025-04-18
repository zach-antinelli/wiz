output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "ID of the VPC associated with the cluster"
  value       = module.vpc.vpc_id
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the cluster"
  value       = aws_security_group.cluster_sg.id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with the cluster"
  value       = module.eks.cluster_iam_role_name
}

output "private_subnets" {
  description = "List of private subnet IDs used by the cluster"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.private_subnets
}

output "update_kubconfig" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "management_ip" {
  description = "Management IP Added to cluster public API access SG"
  value       = "The management IP ${local.management_ip_cidr} has been added to the cluster public API access security group"
}

output "admin_user" {
  description = "Admin user added to the cluster"
  value       = "The IAM user ${local.management_ip_cidr} has been added to the cluster aws-auth configmap"
}



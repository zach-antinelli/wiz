
output "eks_app_pod_sg_id" {
  description = "Security group ID for the web app pod"
  value       = aws_security_group.app_sg.id
}

output "eks_app_alb_sg_id" {
  description = "Security group ID for the application load balancer"
  value       = aws_security_group.alb_sg.id
}

output "eks_cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "vpc_private_subnets" {
  description = "List of private subnet IDs used by the cluster"
  value       = module.vpc.private_subnets
}

output "vpc_public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "admin_user" {
  description = "Admin user added to the cluster"
  value       = "The IAM user ${local.iam_user} has been added to the cluster aws-auth configmap"
}

output "db_vm_id" {
  description = "Instance ID of the database VM instance"
  value       = aws_instance.db_vm.id
}

output "db_vm_ip" {
  description = "Public IP of the database VM instance"
  value       = aws_instance.db_vm.public_ip
}

output "db_vm_mysql_backup_location" {
  description = "S3 location for MySQL backups"
  value       = "s3://${var.bucket_name}/backups/mysql/"
}

output "eks_cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_management_ip" {
  value       = "The management IP ${var.management_ip_cidr} has been added to the cluster public API access security group"
  description = "Management IP Added to cluster public API access SG"
}

output "eks_update_kubeconfig" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "s3_bucket_uri" {
  value       = aws_s3_bucket.public_bucket.bucket_domain_name
  description = "S3 website URL"
}

output "s3_bucket_site_uri" {
  value       = "${aws_s3_bucket.public_bucket.bucket_domain_name}/index.html"
  description = "S3 website URL"
}

output "vpc_id" {
  description = "ID of the VPC associated with the cluster"
  value       = module.vpc.vpc_id
}

output "vpc_private_subnets" {
  description = "List of private subnet IDs used by the cluster"
  value       = module.vpc.private_subnets
}

output "vpc_public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.private_subnets
}

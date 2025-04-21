variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "tech-exercise"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use for the subnets in the VPC"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets to host load balancers"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "node_group_min_size" {
  description = "Minimum size of the node group"
  type        = number
  default     = 3
}

variable "node_group_max_size" {
  description = "Max size of the node group"
  type        = number
  default     = 3
}

variable "node_group_desired_size" {
  description = "Desired size of the node group"
  type        = number
  default     = 3
}

variable "node_volume_size" {
  description = "Size of the node EBS volume"
  type        = number
  default     = 50
}


variable "node_group_capacity_type" {
  description = "Capacity type for the node group"
  type        = string
  default     = "ON_DEMAND"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "prod"
    Managed_by  = "Terraform"
    Project     = "Wiz Tech Exercise"
    Owner       = "zantinelli"
  }
}

variable "bucket_name" {
  description = "Name of the S3 bucket to be created"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9.-]{3,63}$", var.bucket_name))
    error_message = "Bucket name must be lowercase, between 3 and 63 characters, and can only contain lowercase letters, numbers, dots, and hyphens."
  }
}

variable "key_name" {
  description = "SSH Key pair for DB VM"
  type        = string
}

variable "db_password" {
  description = "Password for DB"
  type        = string
}

variable "app_name" {
  description = "Web app name"
  type        = string
}

variable "management_ip_cidr" {
  description = "CIDR block for management IP"
  type        = string
}
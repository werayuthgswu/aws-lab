variable "aws_region" {
  description = "AWS region used for all resources."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "eks-workshop-2"
}

variable "cluster_version" {
  description = "EKS cluster version."
  type        = string
  default     = "1.35"
}

variable "ami_release_version" {
  description = "EKS optimized AMI release version for the managed node group."
  type        = string
  default     = "1.35.6-20260818"
}

variable "cluster_role_arn" {
  description = "Existing IAM role ARN for the EKS cluster. Required for lab environments without iam:CreateRole."
  type        = string
  default     = "arn:aws:iam::722065297261:role/LabRole"
}

variable "node_group_role_arn" {
  description = "Existing IAM role ARN for the EKS managed node group. Required for lab environments without iam:CreateRole."
  type        = string
  default     = "arn:aws:iam::722065297261:role/LabRole"
}

variable "vpc_cidr" {
  description = "CIDR block used for the Amazon VPC created for Amazon EKS."
  type        = string
  default     = "10.100.0.0/16"
}

variable "remote_network_cidr" {
  description = "Remote CIDR block used for EKS Hybrid Nodes."
  type        = string
  default     = "10.110.0.0/16"
}

variable "remote_pod_cidr" {
  description = "Remote pod CIDR block used for EKS Hybrid Nodes."
  type        = string
  default     = "10.111.0.0/16"
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the EKS private API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API server endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Create an EKS access entry that grants the Terraform caller cluster admin permissions."
  type        = bool
  default     = true 
}

variable "enable_irsa" {
  description = "Create an OIDC provider for IAM Roles for Service Accounts (IRSA)."
  type        = bool
  default     = false
}

variable "cluster_log_retention_days" {
  description = "Retention in days for the EKS control plane CloudWatch log group."
  type        = number
  default     = 90
}

variable "node_instance_types" {
  description = "Instance types used by the managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_min_size" {
  description = "Minimum size of the managed node group."
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum size of the managed node group."
  type        = number
  default     = 6
}

variable "node_desired_size" {
  description = "Desired size of the managed node group."
  type        = number
  default     = 3
}

variable "node_labels" {
  description = "Kubernetes labels applied to the managed node group."
  type        = map(string)
  default = {
    workshop-default = "yes"
  }
}

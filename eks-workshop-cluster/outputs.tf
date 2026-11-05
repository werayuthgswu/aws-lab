output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data for the EKS cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN of the IRSA OIDC provider (null when enable_irsa = false)."
  value       = try(aws_iam_openid_connect_provider.this[0].arn, null)
}

output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by the EKS control plane and node group."
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "cluster_security_group_id" {
  description = "Explicit EKS cluster security group ID."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "EKS node security group ID."
  value       = aws_security_group.node.id
}

output "node_group_name" {
  description = "Managed node group name."
  value       = aws_eks_node_group.default.node_group_name
}

output "node_group_role_arn" {
  description = "IAM role ARN used by the managed node group."
  value       = aws_eks_node_group.default.node_role_arn
}

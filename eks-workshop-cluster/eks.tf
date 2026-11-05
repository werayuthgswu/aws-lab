################################################################################
# EKS control plane
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_days
  skip_destroy      = false

  tags = merge(local.tags, {
    Name = "/aws/eks/${var.cluster_name}/cluster"
  })
}

resource "aws_eks_cluster" "this" {
  name                          = var.cluster_name
  version                       = var.cluster_version
  role_arn                      = var.cluster_role_arn
  enabled_cluster_log_types     = ["audit", "api", "authenticator"]
  bootstrap_self_managed_addons = false

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"

    # Handled explicitly below with an access entry so that it can be
    # enabled/disabled without recreating the cluster.
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.endpoint_public_access_cidrs
  }

  remote_network_config {
    remote_node_networks {
      cidrs = [var.remote_network_cidr]
    }

    remote_pod_networks {
      cidrs = [var.remote_pod_cidr]
    }
  }

  tags = local.cluster_tags

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_security_group_rule.cluster_ingress_nodes_443,
    aws_security_group_rule.cluster_ingress_hybrid_node,
    aws_security_group_rule.cluster_ingress_hybrid_pod,
    aws_security_group_rule.cluster_egress_all,
    aws_security_group_rule.node_ingress_cluster_443,
    aws_security_group_rule.node_ingress_cluster_kubelet,
    aws_security_group_rule.node_ingress_self_coredns_tcp,
    aws_security_group_rule.node_ingress_self_coredns_udp,
    aws_security_group_rule.node_ingress_self_ephemeral,
    aws_security_group_rule.node_ingress_cluster_webhooks,
    aws_security_group_rule.node_ingress_hybrid_node,
    aws_security_group_rule.node_ingress_hybrid_pod,
    aws_security_group_rule.node_egress_all,
  ]

  lifecycle {
    ignore_changes = [
      access_config[0].bootstrap_cluster_creator_admin_permissions,
      bootstrap_self_managed_addons,
    ]
  }
}

# The EKS service creates its own primary security group. Tag it the same way
# the module did so Karpenter and other tag-based discovery keep working.
resource "aws_ec2_tag" "cluster_primary_security_group" {
  for_each = local.cluster_tags

  resource_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  key         = each.key
  value       = each.value
}

################################################################################
# IRSA (OIDC provider)
################################################################################
data "tls_certificate" "this" {
  count = var.enable_irsa ? 1 : 0

  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  count = var.enable_irsa ? 1 : 0

  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this[0].certificates[0].sha1_fingerprint]

  tags = merge(local.tags, {
    Name = "${var.cluster_name}-eks-irsa"
  })
}

################################################################################
# Cluster creator admin access
################################################################################

resource "aws_eks_access_entry" "cluster_creator" {
  count = var.enable_cluster_creator_admin_permissions ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = local.caller_issuer_arn
  type          = "STANDARD"

  tags = local.tags
}

resource "aws_eks_access_policy_association" "cluster_creator_admin" {
  count = var.enable_cluster_creator_admin_permissions ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = local.caller_issuer_arn
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_creator]
}

################################################################################
# Managed node group
################################################################################

resource "aws_launch_template" "default" {
  name                   = "${var.cluster_name}-default-node"
  update_default_version = true

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }

  vpc_security_group_ids = [
    aws_security_group.node.id,
    # Attach the EKS-managed primary SG so node-to-node traffic keeps the
    # same all-traffic behavior as the module-based configuration.
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
  ]

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.cluster_tags, {
      Name = "default"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.cluster_tags, {
      Name = "default"
    })
  }

  tag_specifications {
    resource_type = "network-interface"
    tags = merge(local.cluster_tags, {
      Name = "default"
    })
  }

  tags = merge(local.cluster_tags, {
    Name = "${var.cluster_name}-default-node"
  })
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "default"
  node_role_arn   = var.node_group_role_arn
  subnet_ids      = aws_subnet.private[*].id

  version         = var.cluster_version
  release_version = var.ami_release_version
  ami_type        = "AL2023_x86_64_STANDARD"
  capacity_type   = "ON_DEMAND"
  instance_types  = var.node_instance_types

  force_update_version = true
  labels               = var.node_labels

  scaling_config {
    min_size     = var.node_min_size
    max_size     = var.node_max_size
    desired_size = var.node_desired_size
  }

  update_config {
    max_unavailable_percentage = 50
  }

  launch_template {
    id      = aws_launch_template.default.id
    version = aws_launch_template.default.latest_version
  }

  tags = local.cluster_tags

  depends_on = [
    aws_eks_addon.vpc_cni,
    aws_route.private_nat_gateway,
    aws_route_table_association.private,
    aws_security_group_rule.node_ingress_cluster_443,
    aws_security_group_rule.node_ingress_cluster_kubelet,
    aws_security_group_rule.node_ingress_self_coredns_tcp,
    aws_security_group_rule.node_ingress_self_coredns_udp,
    aws_security_group_rule.node_ingress_self_ephemeral,
    aws_security_group_rule.node_ingress_cluster_webhooks,
    aws_security_group_rule.node_ingress_hybrid_node,
    aws_security_group_rule.node_ingress_hybrid_pod,
    aws_security_group_rule.node_egress_all,
  ]
}

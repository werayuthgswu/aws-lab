################################################################################
# Security groups
#
# The module-based configuration used create_security_group = false and
# create_node_security_group = false, which also made its "additional rules"
# no-ops. These explicit security groups make the hybrid-node rules effective
# and give you a single place to control all cluster/node traffic.
################################################################################

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = "${var.cluster_name}-cluster"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cluster_ingress_nodes_443" {
  description              = "Node groups to cluster API"
  type                     = "ingress"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
}

resource "aws_security_group_rule" "cluster_ingress_hybrid_node" {
  description       = "Allow all traffic from remote node network"
  type              = "ingress"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = [var.remote_network_cidr]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}

resource "aws_security_group_rule" "cluster_ingress_hybrid_pod" {
  description       = "Allow all traffic from remote pod network"
  type              = "ingress"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = [var.remote_pod_cidr]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}

resource "aws_security_group_rule" "cluster_egress_all" {
  description       = "Allow all egress"
  type              = "egress"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}

resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-node"
  description = "EKS node shared security group"
  vpc_id      = aws_vpc.this.id

  tags = merge(local.cluster_tags, {
    Name                                        = "${var.cluster_name}-node"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "node_ingress_cluster_443" {
  description              = "Cluster API to node groups"
  type                     = "ingress"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
}

resource "aws_security_group_rule" "node_ingress_cluster_kubelet" {
  description              = "Cluster API to node kubelets"
  type                     = "ingress"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
  protocol                 = "tcp"
  from_port                = 10250
  to_port                  = 10250
}

resource "aws_security_group_rule" "node_ingress_self_coredns_tcp" {
  description       = "Node to node CoreDNS"
  type              = "ingress"
  security_group_id = aws_security_group.node.id
  self              = true
  protocol          = "tcp"
  from_port         = 53
  to_port           = 53
}

resource "aws_security_group_rule" "node_ingress_self_coredns_udp" {
  description       = "Node to node CoreDNS UDP"
  type              = "ingress"
  security_group_id = aws_security_group.node.id
  self              = true
  protocol          = "udp"
  from_port         = 53
  to_port           = 53
}

resource "aws_security_group_rule" "node_ingress_self_ephemeral" {
  description       = "Node to node ingress on ephemeral ports"
  type              = "ingress"
  security_group_id = aws_security_group.node.id
  self              = true
  protocol          = "tcp"
  from_port         = 1025
  to_port           = 65535
}

# Recommended webhook/metrics ports used by common cluster add-ons.
resource "aws_security_group_rule" "node_ingress_cluster_webhooks" {
  for_each = {
    metrics_server_legacy = 4443
    metrics_server        = 10251
    prometheus_adapter    = 6443
    karpenter             = 8443
    ingress_controller    = 9443
  }

  description              = "Cluster API to node ${each.value}/tcp webhook"
  type                     = "ingress"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
  protocol                 = "tcp"
  from_port                = each.value
  to_port                  = each.value
}

resource "aws_security_group_rule" "node_ingress_hybrid_node" {
  description       = "Allow all traffic from remote node network"
  type              = "ingress"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = [var.remote_network_cidr]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}

resource "aws_security_group_rule" "node_ingress_hybrid_pod" {
  description       = "Allow all traffic from remote pod network"
  type              = "ingress"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = [var.remote_pod_cidr]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}

resource "aws_security_group_rule" "node_egress_all" {
  description       = "Allow all egress"
  type              = "egress"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}

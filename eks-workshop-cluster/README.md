# EKS cluster without Terraform modules

This folder is a module-free conversion of the parent `terraform2` configuration.
All AWS resources are declared directly so behavior can be changed by editing
the resource arguments here.

## Files

| File | Contents |
| --- | --- |
| `providers.tf` | Terraform/provider versions, AWS provider, default tags |
| `main.tf` | Locals, availability zones, account/session data sources |
| `variables.tf` | Inputs (cluster, VPC, node group, endpoints, IRSA) |
| `vpc.tf` | VPC, 3 public + 3 private subnets, IGW, single NAT gateway, route tables, default VPC resources |
| `security-groups.tf` | Explicit cluster and node security groups and all rules |
| `eks.tf` | Control plane, CloudWatch logs, OIDC/IRSA, creator access entry, launch template, managed node group |
| `addons.tf` | `vpc-cni` (before nodes), `coredns`, `kube-proxy` |
| `outputs.tf` | Useful cluster/network outputs |

## Usage

```bash
cd neweks
terraform init
terraform plan -var-file=terraform.tfvars   # if you have one
terraform apply
```

The two IAM roles are still passed in as existing ARNs (`cluster_role_arn` and
`node_group_role_arn`, both defaulting to `LabRole`). No IAM roles are created.

## Behavior carried over from the module-based configuration

- Kubernetes version `1.35`, AMI release `1.35.6-20260818`
- Three private subnets used by the control plane and node group
- One `t3.large` managed node group: min 3 / desired 3 / max 6,
  `max_unavailable_percentage = 50`, label `workshop-default=yes`
- `vpc-cni` installed before compute with the same configuration values
  (pod ENI, prefix delegation, network policy, policy event logs)
- `coredns` and `kube-proxy` installed after the node group
- Control plane logs `audit`, `api`, `authenticator` with a 90-day log group
- OIDC provider for IRSA
- Cluster creator access entry with `AmazonEKSClusterAdminPolicy`
- Hybrid node/pod remote network config and matching security group ingress rules
- Same VPC/subnet CIDR layout, tags, and Karpenter discovery tags

## Notable differences

- **Security groups are now explicit.** The old configuration used
  `create_security_group = false` and `create_node_security_group = false`,
  which also caused `security_group_additional_rules` and
  `node_security_group_additional_rules` to be skipped (the module gates both
  on the corresponding `create_*` flag). The rules for the hybrid node/pod
  CIDRs are therefore effective here. Edit `security-groups.tf` to change them.
- **`ami_release_version` is honored.** The module defaulted to
  `use_latest_ami_release_version = true`, which ignored the supplied value.
  Set `ami_release_version` in `variables.tf` or override it with a
  `.tfvars` file to pin the AMI.
- **Node group name is fixed** to `default` instead of using a generated
  name prefix.
- **The node group uses a custom launch template** so the explicit node
  security group and IMDSv2-only metadata options are applied. The EKS-managed
  primary security group is also attached so node-to-node traffic keeps the
  same all-traffic behavior as before.

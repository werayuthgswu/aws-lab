locals {
  tags = {
    created-by = "eks-workshop-v2"
    env        = var.cluster_name
  }

  cluster_tags = merge(local.tags, {
    "karpenter.sh/discovery" = var.cluster_name
  })

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  # Same layout as the module-based configuration:
  #   public  10.100.0.0/19, 10.100.32.0/19, 10.100.64.0/19
  #   private 10.100.96.0/19, 10.100.128.0/19, 10.100.160.0/19
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 3, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 3, k + 3)]
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  # Derived locally instead of using the aws_iam_session_context data source,
  # which calls iam:GetRole. AWS Academy Learner Lab roles (voclabs) explicitly
  # deny iam:GetRole, so that data source cannot be used there.
  caller_identity_arn = data.aws_caller_identity.current.arn
  caller_issuer_arn = (
    can(regex("^arn:[^:]+:sts::[0-9]+:assumed-role/", local.caller_identity_arn))
    ? replace(local.caller_identity_arn, "/^arn:([^:]+):sts::([0-9]+):assumed-role\\/([^/]+)\\/.*$/", "arn:$1:iam::$2:role/$3")
    : local.caller_identity_arn
  )
}

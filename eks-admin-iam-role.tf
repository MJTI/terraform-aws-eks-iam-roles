locals {
  devops_arns = [for user in aws_iam_user.devops : user.arn]
}

resource "aws_iam_role" "eks-devops-admin" {
  name = "${var.env}-${var.project}-eks-devops-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Principal = {
          AWS = local.devops_arns
        }
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/Team" = "DevOps"
          }
        }
      }
    ]
  })

  tags = {
    Name       = "eks-devops-admin"
    Managed_By = "Terraform"
    Project    = var.project
  }

  depends_on = [local.devops_arns]
}

resource "aws_iam_policy" "eks-cluster-access" {
  name = "${var.env}-${var.project}-eks-devops-admin-access"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "eks:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition" : {
                "StringEquals" : {
                    "iam:PassedToService" : "eks.amazonaws.com"
                }
            }
        }
    ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "eks-devops-admin-access" {
  role       = aws_iam_role.eks-devops-admin.name
  policy_arn = aws_iam_policy.eks-cluster-access.arn
}

resource "aws_iam_policy" "assume-devops-admin-role" {
  name = "${var.env}-${var.project}-eks-assume-devops-admin-role"

  policy = jsonencode({

    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.eks-devops-admin.arn
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "eks-devops-admin-access" {
  group      = aws_iam_group.devops_group.name
  policy_arn = aws_iam_policy.assume-devops-admin-role.arn
}

resource "kubernetes_cluster_role_binding_v1" "eks-devops-admin-role-binding" {
  metadata {
    name = "devops-admin-cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "devops-admin"
  }
}

resource "aws_eks_access_entry" "devops-admin-access" {
  cluster_name      = var.eks_cluster_name
  principal_arn     = aws_iam_role.eks-devops-admin.arn
  kubernetes_groups = ["devops-admin"]
}

resource "kubernetes_cluster_role_binding_v1" "eks-admin-role-binding" {
  count = length(var.cluster_admin_access)

  metadata {
    name = "admin-cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "${var.project}-admin"
  }
}

resource "aws_eks_access_entry" "cluster-admin-access" {
  count = length(var.cluster_admin_access)

  cluster_name  = var.eks_cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.cluster_admin_access[count.index]}"
  user_name     = "${var.project}-admin"
}
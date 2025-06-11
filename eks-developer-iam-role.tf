data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eks-developer" {
  name = "${var.env}-${var.project}-eks-developer"

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
          AWS = "*"
        }
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/Team" = "Developer"
          }
        }
      }
    ]
  })

  tags = {
    Name       = "eks-developer"
    Managed_By = "Terraform"
    Project    = var.project
  }
}

resource "aws_iam_policy" "eks-developer-cluster-access" {
  name = "${var.env}-${var.project}-eks-developer-access"

  policy = jsonencode({

    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "eks:ListClusters"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
      }
    ]

  })
}

resource "aws_iam_role_policy_attachment" "eks-developer-access" {
  role       = aws_iam_role.eks-developer.name
  policy_arn = aws_iam_policy.eks-developer-cluster-access.arn
}

resource "aws_iam_policy" "assume-developer-role" {
  name = "${var.env}-${var.project}-eks-assume-developer-role"

  policy = jsonencode({

    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.eks-developer.arn
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "eks-developer-access" {
  group      = aws_iam_group.developer_group.name
  policy_arn = aws_iam_policy.assume-developer-role.arn
}

resource "kubernetes_cluster_role" "developer" {
  metadata {
    name = "eks-developer"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "eks-developer-role-binding" {
  metadata {
    name = "developer-cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "eks-developer"
  }
  subject {
    kind = "Group"
    name = "developer"
  }
}

resource "aws_eks_access_entry" "developer-access" {
  cluster_name      = var.cluster_name
  principal_arn     = aws_iam_role.eks-developer.arn
  kubernetes_groups = ["developer"]
}
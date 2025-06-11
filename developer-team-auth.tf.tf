resource "aws_iam_user" "developer" {
  count = length(var.developer_users)

  name          = var.developer_users[count.index]
  force_destroy = true
  tags = {
    Team       = "Developer"
    Managed_By = "Terraform"
    Project    = var.project
  }

  depends_on = [aws_iam_group.developer_group]
}

resource "aws_iam_group" "developer_group" {
  name = "Developer"
}

resource "aws_iam_user_group_membership" "developer_users" {
  count = length(var.developer_users)

  user   = aws_iam_user.developer[count.index].name
  groups = [aws_iam_group.developer_group.name]

  depends_on = [aws_iam_user.developer]
}
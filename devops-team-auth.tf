resource "aws_iam_user" "devops" {
  count = length(var.devops_users)

  name          = var.devops_users[count.index]
  force_destroy = true
  tags = {
    Team       = "DevOps"
    Managed_By = "Terraform"
    Project    = var.project
  }

  depends_on = [aws_iam_group.devops_group]
}

resource "aws_iam_group" "devops_group" {
  name = "DevOps"
}

resource "aws_iam_user_group_membership" "devops_users" {
  count = length(var.devops_users)

  user   = aws_iam_user.devops[count.index].name
  groups = [aws_iam_group.devops_group.name]

  depends_on = [aws_iam_user.devops]
}
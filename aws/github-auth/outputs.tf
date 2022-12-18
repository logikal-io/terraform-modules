output "iam_role_arns" {
  value = {for role in keys(var.role_accesses) : role => aws_iam_role.github_actions[role].arn}
  description = "The ARNs of the AWS IAM roles used with GitHub Actions"
}

output "iam_role_names" {
  value = {for role in keys(var.role_accesses) : role => aws_iam_role.github_actions[role].name}
  description = "The names of the AWS IAM roles used with GitHub Actions"
}

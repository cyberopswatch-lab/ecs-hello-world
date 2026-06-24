output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "Set this as the AWS_GITHUB_ACTIONS_ROLE_ARN repository variable in GitHub"
}

output "tf_state_bucket" {
  value       = aws_s3_bucket.tf_state.bucket
  description = "Set this as the TF_STATE_BUCKET repository variable in GitHub"
}

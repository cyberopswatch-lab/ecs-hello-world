output "ecr_repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "codestar_connection_arn" {
  value       = aws_codestarconnections_connection.github.arn
  description = "Will be PENDING until you authorize it in the AWS console (Developer Tools > Connections)"
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.this.name
}

output "codepipeline_name" {
  value = aws_codepipeline.this.name
}

output "autoscaling_group_name" {
  value       = aws_autoscaling_group.ecs_hosts.name
  description = "Look up this ASG's EC2 instance in the console to get its public IP"
}

output "pipeline_artifact_bucket" {
  value = aws_s3_bucket.pipeline_artifacts.bucket
}

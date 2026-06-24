resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled" # keep this in the free tier; flip to "enabled" if you want CloudWatch Container Insights
  }

  tags = {
    Project = var.project_name
  }
}

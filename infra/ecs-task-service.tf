resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  # NOTE: this image tag is a placeholder. The first successful pipeline run
  # pushes the real image and CodePipeline's ECS deploy action registers a
  # new task definition revision pointing at it.
  container_definitions = jsonencode([
    {
      name      = "web-container"
      image     = "${aws_ecr_repository.this.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
    }
  ])

  lifecycle {
    ignore_changes = [container_definitions] # CodePipeline manages this after the first deploy
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    base              = 1
    weight            = 1
  }

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  lifecycle {
    ignore_changes = [task_definition] # CodePipeline registers new revisions after deploys
  }

  depends_on = [aws_ecs_cluster_capacity_providers.this]
}

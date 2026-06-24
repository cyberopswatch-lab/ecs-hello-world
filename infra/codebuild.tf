resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/codebuild/${var.project_name}"
  retention_in_days = 14
}

resource "aws_codebuild_project" "this" {
  name         = "${var.project_name}-build"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0" # Ubuntu standard runtime
    type            = "LINUX_CONTAINER"
    privileged_mode = true # required: lets CodeBuild run `docker build`

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.this.repository_url
    }
  }

  source {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }
}

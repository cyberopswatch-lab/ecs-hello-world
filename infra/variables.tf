variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as a prefix for all resources (lowercase, no spaces)"
  type        = string
  default     = "retail-catalog"
}

variable "github_owner" {
  description = "GitHub username or org that owns the app repo (e.g. the repo containing index.html / Dockerfile / buildspec.yml)"
  type        = string
}

variable "github_repo" {
  description = "Name of the GitHub repo CodePipeline should watch"
  type        = string
  default     = "ecs-hello-world"
}

variable "github_branch" {
  description = "Branch CodePipeline triggers on"
  type        = string
  default     = "main"
}

variable "instance_type" {
  description = "EC2 instance type for the ECS container host (free-tier eligible)"
  type        = string
  default     = "t3.micro"
}

variable "container_port" {
  description = "Port the container listens on / is mapped to on the host"
  type        = number
  default     = 80
}

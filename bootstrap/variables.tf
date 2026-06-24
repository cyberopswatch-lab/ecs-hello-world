variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name prefix, should match the one used in /infra"
  type        = string
  default     = "retail-catalog"
}

variable "github_owner" {
  description = "GitHub username or org that owns the repo containing /infra"
  type        = string
}

variable "github_repo" {
  description = "Name of the repo containing /infra and the .github/workflows folder"
  type        = string
}

variable "github_branch" {
  description = "Branch GitHub Actions is allowed to deploy from"
  type        = string
  default     = "main"
}

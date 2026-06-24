terraform {
  required_version = ">= 1.10.0" # 1.10+ for S3 native state locking (use_lockfile)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Partial backend config: bucket/key/region/use_lockfile are supplied via
  # `-backend-config` flags at `terraform init` time (see
  # .github/workflows/deploy-infra.yml) so nothing AWS-account-specific is
  # hardcoded in this repo.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

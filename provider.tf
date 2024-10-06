terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Provider for us-east-1 (required for ACM certificate used by CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

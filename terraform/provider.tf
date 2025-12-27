terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Optional remote backend configuration (commented out). If you enable remote state, fill `bucket` and `dynamodb_table` vars.
# terraform {
#   backend "s3" {
#     bucket         = "<your-tf-state-bucket>"
#     key            = "jenkins-docker-demo/terraform.tfstate"
#     region         = "eu-north-1"
#     dynamodb_table = "<your-lock-table>"
#     encrypt        = true
#   }
# }

provider "aws" {
  region = var.region
}

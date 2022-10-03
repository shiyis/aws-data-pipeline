
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.1"
    }
  }

  cloud {
    organization = "quintrix-aws-data-pipeline"

    workspaces {
      name = "aws-data-streaming-pipeline"
    }
}
}


provider "aws" {
  region = var.aws_region
  access_key = ""
  secret_key = ""
  assume_role {
    duration_seconds = 3600
    session_name = "session-name"
    role_arn = var.aws_deployment_role
  }

  #TODO
  #configure aws roles in terraform template
  #assume_role{
  #  role_arn = ""
  #  session_name = ""
  #  external_id = ""
  #}
}
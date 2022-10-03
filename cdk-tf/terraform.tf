provider "aws" {
  region     = "us-west-1"
  access_key = ""
  secret_key = ""

  #TODO
  #configure aws roles in terraform template
  #assume_role{
  #  role_arn = ""
  #  session_name = ""
  #  external_id = ""
  #}
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  cloud {
    organization = "quintrix-aws-data-pipeline"

    workspaces {
      name = "aws-data-streaming-pipeline"
    }
  }

}

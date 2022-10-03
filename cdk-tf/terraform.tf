provider "aws" {
  region     = "us-west-1"
  access_key = "AKIAW7FIH46GO5UPENR3"
  secret_key = "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"

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

# Here we will call the codepipeline module and sagemaker module. 

module "codepipeline" {
  source = "rpstreef/codepipeline-sam/aws"
  version = "1.3.0"

  resource_tag_name = var.resource_tag_name
  environment       = var.environment
  region            = "us-east-1"

  github_token        = var.github_token
  github_owner        = var.github_owner
  github_repo         = var.github_repo

  build_image = "aws/codebuild/standard:4.0"
  buildspec   = data.template_file.buildspec.rendered

  stack_name = "Group3-pipeline"

  environment_variable_map = [
    {
      name  = "REGION"
      value = "us-east-1"
      type  = "PLAINTEXT"
    }
  ]
}

module "sagemaker" {
    source = ".\\..\\modules\\sagemaker"
}


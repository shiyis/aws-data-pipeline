#Create Sagemaker notebook instance
resource "aws_sagemaker_notebook_instance" "Sagemaker-instance" {
  name = "Data-Sagemaker"
  role_arn =
  instance_type =
  tags = {
    Name = "AWS Pipeline"
  }
}

#OPTION 2
#CreateSagemaker repo w/ instance
resource "aws_sagemaker_code_repository" "Sagemaker-Repo" {
  code_repository_name = "Instance-repo"
  git_config {
    repository_url = ""
  }
}
resource "aws_sagemaker_notebook_instance" "Sagemaker-instance" {
  instance_type = ""
  name          = "Data-Sagemaker"
  role_arn      = ""
  default_code_repository = ""

  tags = {
    Name =
  }
}

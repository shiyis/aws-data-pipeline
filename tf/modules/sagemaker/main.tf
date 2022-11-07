#Create Sagemaker notebook instance
# resource "aws_sagemaker_notebook_instance" "Sagemaker-instance" {
#   name = "Data-Sagemaker"
#   role_arn = ""
#   instance_type = ""
#   tags = {
#     Name = "AWS Pipeline"
#   }
# }

#OPTION 2 
#CreateSagemaker repo w/ instance
resource "aws_sagemaker_code_repository" "sagemaker-Repo" {
  code_repository_name = "aws-data-pipeline"
  git_config {
    repository_url = "https://github.com/shiyis/aws-data-pipeline"
  }
}

resource "aws_sagemaker_notebook_lifestyle_configuration" "config" {
  name = "lda_cycle"
  on_create = base64encode( # provide a bash script that runs on CREATION of notebook
    ""
  )
  on_start = base64encode( # provide a bash script that runs on STARTING notebook from a stop
    ""
  )
}

resource "aws_sagemaker_notebook_instance" "sagemaker-instance" {
  instance_type = var.instance_type
  name          = "Data-Sagemaker"
  role_arn      = aws_iam_role.sagemaker_role.arn
  default_code_repository = aws_sagemaker_code_repository.sagemaker-Repo.code_repository_name

  lifecycle_config_name = "lda_cycle"

  tags = {
    Name = ""
  }
}

# The necessary IAM resources

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "sagemaker_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:Put*", 
      "sagemaker:StartNotebookInstance", 
      "sagemaker:StopNotebookInstance"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "sagemaker_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  name = "lda-sagemaker-role"
}

resource "aws_iam_policy" "sagemaker_policy" {
  policy = data.aws_iam_policy_document.sagemaker_policy_doc.json
  name = "lda-sagemaker-policy"
}

resource "aws_iam_role_policy_attachment" "sagemaker_attach" {
  policy_arn = aws_iam_policy.sagemaker_policy.arn
  role = aws_iam_role.sagemaker_role.name
}

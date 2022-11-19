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

  tags = var.common_tags
}

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "config" {
  name = "lda-cycle"
  on_create = base64encode(
    var.on_create
  )
  on_start = base64encode(
    var.on_start
  )
}

resource "aws_sagemaker_notebook_instance" "sagemaker_instance" {
  instance_type = var.instance_type
  name          = "Data-Sagemaker"
  role_arn      = aws_iam_role.sagemaker_role.arn
  default_code_repository = aws_sagemaker_code_repository.sagemaker-Repo.code_repository_name
  subnet_id = var.subnet_id
  security_groups = [aws_security_group.sagemaker_security_group.id]

  lifecycle_config_name = "lda-cycle"

  tags = var.common_tags
}

resource "aws_security_group" "sagemaker_security_group" {
  vpc_id = var.vpc_id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.common_tags
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
      "s3:Put*"
      ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "sagemaker:DescribeNotebookInstance",
      "sagemaker:StartNotebookInstance", 
      "sagemaker:StopNotebookInstance"
      ]
      resources = [aws_sagemaker_notebook_instance.sagemaker_instance.arn]
  }
}

resource "aws_iam_role" "sagemaker_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  name = "lda-sagemaker-role"

  tags = var.common_tags
}

resource "aws_iam_policy" "sagemaker_policy" {
  policy = data.aws_iam_policy_document.sagemaker_policy_doc.json
  name = "lda-sagemaker-policy"

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "sagemaker_attach" {
  policy_arn = aws_iam_policy.sagemaker_policy.arn
  role = aws_iam_role.sagemaker_role.name
}

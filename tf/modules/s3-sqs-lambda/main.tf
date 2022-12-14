# Takes in the bucket that data is stored in, creates bucket policy, sqs queue, lambda function. 
# Lambda function will be the one that processes data and feeds it to sagemaker. We may not need 
# this, considering sagemaker accesses the s3 bucket directly.

# Important note: This is where we will create and attach the bucket policy, so anything that needs access to s3
# needs to be included in the variables of this module


#Create SQS
resource "aws_sqs_queue" "queue" {
  name                      = "SQS-Lambda"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "arn:aws:s3:::${var.bucket-name}}"
        }
      }
    }
  ]
}
POLICY

  fifo_queue                = false
  delay_seconds             = 0
  # max_message_size          = 
  # message_retention_seconds = 
  # receive_wait_time_seconds = 

  tags = {
    Environment = " "
  }
}

#SQS mapping for Lambda
resource "aws_lambda_event_source_mapping" "sqsLambda" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name = aws_lambda_function.test_lambda.arn
}

#Create Lambda role
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  # path = ""

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


#Create Lambda function
resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  # filename      = " "
  function_name = " "
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = " "
  s3_bucket     = ""
  # s3_key        = ""
}



#Create Policy for IAM Role w/ specified access to s3
resource "aws_iam_policy" "Lambda-S3-Policy" {
  name = "LambdaS3-test-policy"
  descriptiom = "Lambda access to S3"
  policy = <<EOF
{ 
"Version": "2012-10-17"
"Statement": [
  {
  "Effect": "Allow",
  "Action": [
      "logs:*"
    ],
    "Resource": "arn:aws:logs:*:*:*"
  },
  {
      "Effect": "Allow",
      "Action": [
        "s3:*"
        ],
      "Resource": "arn:aws:s3:::<BUCKET-NAME>*"
  }
  ]
}
  EOF
}

#Attach IAM Role and Policy
resource "aws_iam_role_policy_attachment" "role-attach" {
  role = "aws_iam_role.iam_for_lambda.name"
  policy = "aws_iam_policy.Lambda-S3-Policy.arn"
}

#Create SQS
resource "aws_sqs_queue" "queue" {
  name = "receive--queue"
  fifo_queue = false
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:s3-event-notification-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.bucket.arn}" }
      }
    }
  ]
}
POLICY
}

#Name generator for S3 Bucket
resource "random_pet" "this" {
  length = 3
}
resource "aws_s3_bucket" "bucket" {
  bucket = "testbucket-${random_pet.this.id}"
}

#create S3 bucket
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  queue {
    queue_arn     = aws_sqs_queue.queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

#Create cloudwatch event
resource "aws_cloudwatch_event_rule" "event-schedule" {
  name = "timed_event"
  schedule_expression = local.time_expression ####
  arn  = ""
  rule = ""
}
resource "aws_cloudwatch_event_target" "event_target" {
  arn  = aws_sqs_queue.queue.arn
  rule = aws_cloudwatch_event_rule.event-schedule.name
}

#data pipeline
data "aws_datapipeline_pipeline" "PIPE" {
  pipeline_id = "pipelineID"
}

#Create Lambda role
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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
  filename      = " "
  function_name = " "
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = " "
}

#SQS mapping for Lambda
resource "aws_lambda_event_source_mapping" "sqsLambda" {
  event_source_arn = aws_sqs_queue.queue.arn
  function_name = aws_lambda_function.test_lambda.arn
}


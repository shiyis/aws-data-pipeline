/*
This module takes the place of the eventbridge-sqs-lambda module. If using this module, don't call
the other one. Here, we will create a statemachine and three lambda functions, as well as the 
policies and roles for all of them.
*/

# Lambda functions first

resource "aws_lambda_function" "filtered_stream" {

  function_name = "filtered_stream"
  description   = "Function that streams tweets"
  role          = aws_iam_role.filtered_stream_role.arn

  #filename = "test.zip" # If using a filename, do not use s3 bucket
  s3_bucket = "${var.code_bucket_name}/lambda_code/filtered_stream.zip" # If using s3 bucket (location), do not use filename
  runtime = "python3.8"
  handler = "test.lambda_handler"
  timeout = 600 # 3 (seconds) is default, we will be using something larger
}

resource "aws_lambda_function" "preprocess" {

  function_name = "preprocess"
  description   = "Function for partial processing of twitter data"
  role          = aws_iam_role.preprocess_role.arn

  #filename = "test.zip" # If using a filename, do not use s3 bucket
  s3_bucket = "${var.code_bucket_name}/lambda_code/preprocess.zip" # If using s3 bucket (location), do not use filename
  runtime = "python3.8"
  handler = "test.lambda_handler"
  timeout = 600 # 3 (seconds) is default, we will be using something larger
}

resource "aws_lambda_function" "load_data" {

  function_name = "load_data"
  description   = "Function that loads data into s3 bucket"
  role          = aws_iam_role.load_data_role.arn

  #filename = "test.zip" # If using a filename, do not use s3 bucket
  s3_bucket = "${var.code_bucket_name}/lambda_code/load_data.zip" # If using s3 bucket (location), do not use filename
  runtime = "python3.8"
  handler = "test.lambda_handler"
  timeout = 600 # 3 (seconds) is default, we will be using something larger
}

# Functions created, moving on to roles for them
# Start with policy documents

data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    sid    = "AssumeRoleLambda"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "filtered_stream_policy_doc" {
  statement {
    sid    = "FilteredStreamPolicy"
    effect = "Allow"
    actions = [
      "s3:*",
      "ssm:GetParameter*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [aws_lambda_function.filtered_stream.arn]
  }
}

data "aws_iam_policy_document" "preprocess_policy_doc" {
  statement {
    sid    = "PreprocessPolicy"
    effect = "Allow"
    actions = [
      "s3:*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [aws_lambda_function.preprocess.arn]
  }
}

data "aws_iam_policy_document" "load_data_policy_doc" {
  statement {
    sid    = "LoadDataPolicy"
    effect = "Allow"
    actions = [
      "s3:*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [aws_lambda_function.load_data.arn]
  }
}

# Now we create the role and policy resources
resource "aws_iam_role" "filtered_stream_role" {
  name = "filtered_stream_lambda_role"

  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_iam_policy" "filtered_stream_policy" {
  name = "filtered_stream_policy"

  policy = data.aws_iam_policy_document.filtered_stream_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "filtered_stream_attach" {
  role       = aws_iam_role.filtered_stream_role.name
  policy_arn = aws_iam_policy.filtered_stream_policy.arn
}

resource "aws_iam_role" "preprocess_role" {
  name = "preprocess_lambda_role"

  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_iam_policy" "preprocess_policy" {
  name = "preprocess_policy"

  policy = data.aws_iam_policy_document.preprocess_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "preprocess_attach" {
  role       = aws_iam_role.preprocess_role.name
  policy_arn = aws_iam_policy.preprocess_policy.arn
}

resource "aws_iam_role" "load_data_role" {
  name = "load_data_lambda_role"

  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_iam_policy" "load_data_policy" {
  name = "load_data_policy"

  policy = data.aws_iam_policy_document.load_data_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "load_data_attach" {
  role       = aws_iam_role.load_data_role.name
  policy_arn = aws_iam_policy.load_data_policy.arn
}

# roles for lambda created, now we create the state machine

resource "aws_sfn_state_machine" "pipeline" {
  depends_on = [
    aws_lambda_function.filtered_stream,
    aws_lambda_function.preprocess,
    aws_lambda_function.load_data
  ]

  name     = "pipeline-sfn"
  role_arn = aws_iam_role.state_machine_role.arn

  definition = <<EOF
{
    "Comment": "A description of my state machine",
    "StartAt": "Twitter Data Poll",
    "States": {
      "Twitter Data Poll": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "OutputPath": "$.Payload",
        "Parameters": {
          "Payload.$": "$",
          "FunctionName": "filtered_stream"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "Next": "Preprocess"
      },
      "Preprocess": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "OutputPath": "$.Payload",
        "Parameters": {
          "Payload.$": "$",
          "FunctionName": "preprocess"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "Next": "Load"
      },
      "Load": {
        "Type": "Task",
        "Resource": "arn:aws:states:::lambda:invoke",
        "OutputPath": "$.Payload",
        "Parameters": {
          "Payload.$": "$",
          "FunctionName": "load_data"
        },
        "Retry": [
          {
            "ErrorEquals": [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ],
            "IntervalSeconds": 2,
            "MaxAttempts": 6,
            "BackoffRate": 2
          }
        ],
        "End": true
      }
    }
  }
    EOF
}

# State machine needs a role

data "aws_iam_policy_document" "state_machine_assume_role" {
  statement {
    sid     = "SFNAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "state_machine_policy_doc" {
  statement {
    sid    = "SFNPolicy"
    effect = "Allow"
    actions = [
      "lambda:*",
      "states:StartExecution",
      "states:StopExecution"
    ]
    resources = [aws_sfn_state_machine.pipeline.arn]
  }
}

resource "aws_iam_role" "state_machine_role" {
  name               = "sfn_role"
  assume_role_policy = data.aws_iam_policy_document.state_machine_assume_role.json
}

resource "aws_iam_policy" "state_machine_policy" {
  name   = "poller_policy"
  policy = data.aws_iam_policy_document.state_machine_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "state_machine_attachment" {
  role       = aws_iam_role.state_machine_role.name
  policy_arn = aws_iam_policy.state_machine_policy.arn
}

# State machine role complete
# Now we need to create the eventbridge rule to schedule this

resource "aws_cloudwatch_event_rule" "state_schedule" {
  depends_on = [
    aws_sfn_state_machine.pipeline
  ]

  name                = "state-machine-schedule"
  schedule_expression = "rate(1 day)"

  is_enabled = var.enable_schedule
}

resource "aws_cloudwatch_event_target" "event_target" {
  rule      = aws_cloudwatch_event_rule.state_schedule.name
  target_id = "StateMachineTarget"
  arn       = aws_sfn_state_machine.pipeline.arn
  role_arn  = aws_iam_role.events_role.arn
}

data "aws_iam_policy_document" "event_rule_assume_role" {
  statement {
    sid    = "EventsAssumeRole"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "event_rule_policy_doc" {
  statement {
    sid       = "EventsPolicy"
    effect    = "Allow"
    actions   = ["states:StartExecution"]
    resources = [aws_cloudwatch_event_target.event_target.arn]
  }
}

resource "aws_iam_role" "events_role" {
  name               = "role_for_event_schedule"
  assume_role_policy = data.aws_iam_policy_document.event_rule_assume_role.json
}

resource "aws_iam_policy" "events_policy" {
  name   = "policy_for_event_schedule"
  policy = data.aws_iam_policy_document.event_rule_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "events_attachment" {
  role       = aws_iam_role.events_role.name
  policy_arn = aws_iam_policy.events_policy.arn
}
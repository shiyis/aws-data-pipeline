# This is where we create the twitter-polling lambda function and the schedule to trigger it, as well as
# the sqs queue that acts as the go-between. Outputs include the arn of the lambda function so that it
# can be included in policies.

/*
If we use the state machine, this entire module is irrelevant. DON'T CALL BOTH THIS MODULE AND state_machine-lambda.
The state machine handles the scheduling and the carrying of data between the lambda functions
*/

locals {
    common_tags = { # Tags to put on every resource
        "Name" = "Final-project"
        "Delete-each-day" = "true"
    }
}

data "aws_iam_policy_document" "assume_role_multi_purpose" { # Can be used for Eventbridge or Lambda
    statement {
      sid = "AssumeRoleEventbridgeAndLambda"
      principals {
        type = "Service"
        identifiers = ["lambda.amazonaws.com", "events.amazonaws.com"]
      }
      effect = "Allow"
      actions = ["sts:AssumeRole"]
    }
}

# Create the queue and attach a policy
resource "aws_sqs_queue" "event_queue" {
    name = event-queue
    fifo = false

    tags = local.common_tags
} # We don't need a policy on the queue because

# data "aws_iam_policy_document" "queue_policy" {
#     statement {
#       sid = "event-bridge-q-permission"
#       effect = "Allow"
#       principals {
#         type = "Service"
#         identifiers = ["events.amazonaws.com"]
#       }
#       actions = ["sqs:*"]
#       resources = [aws_sqs_queue.event_queue.arn]
#     }

#     tags = local.common_tags
# }

# resource "aws_sqs_queue_policy" "q_policy_attach" {
#     queue_url = aws_sqs_queue.event_queue.id

#     policy = data.aws_iam_policy_document.queue_policy.json
# }
# Finished with queue

# Create eventbridge rule and subscribe the queue to it
resource "aws_cloudwatch_event_rule" "cw_schedule" {
    name = "lambda-schedule"
    schedule_expression = var.lambda_schedule

    role_arn = aws_iam_role.events_role.arn

    tags = local.common_tags
}

# Begin policy and role crap
data "aws_iam_policy_document" "eventbridge_policy_document" {
    statement {
        sid = "AllowEventbridgeToAccessQueue"
        effect = "Allow"
        actions = ["sqs:SendMessage"]
    }
}

resource "aws_iam_role" "events_role" {
    name = "eventbridge-role"
    assume_role_policy = data.aws_iam_policy_document.assume_role_multi_purpose.json
    
    tags = local.common_tags
}

resource "aws_iam_policy" "event_policy" {
    name = "policy-for-eventbridge"
    policy = data.aws_iam_policy_document.eventbridge_policy_document.json
}

resource "aws_iam_role_policy_attachment" "event_role_policy_attach" {
    role = aws_iam_role.events_role.name
    policy_arn = aws_iam_policy.event_policy.arn
}
# End policy and role crap

resource "aws_cloudwatch_event_target" "target" { # we use sqs as a target so that it's all loosely-coupled
    target_id = "SendToSQS"
    rule = aws_cloudwatch_event_rule.cw_schedule.name
    arn = aws_sqs_queue.event_queue.arn
}
# finished with eventbridge

# Create Lambda function

/* Notes on lambda function. We know that we want to store code for the function on github, but we
also have the option of storing a deployment package on s3. We should consider both and 
configure this function as needed.
*/
resource "aws_lambda_function" "twitter_poller" {
   
    function_name = "twitter_poller"
    description = "Pulls tweets, may be the function that preprocesses them as well"
    role = aws_iam_role.lambda_execution_role.arn
    
    #filename = "" # local file containing the function code
    #s3_bucket = "" # use a location, not a bucket name
    runtime = "python3.9"
    timeout = 600 # 3 (seconds) is default, we will be using something larger

    tags = local.common_tags
}

resource "aws_lambda_event_source_mapping" "schedule_mapping" {
    event_source_arn = aws_sqs_queue.event_queue.arn
    function_name = aws_lambda_function.twitter_poller.name

    maximum_retry_attempts = 1
}

# Begin policy and role crap again
data "aws_iam_policy_document" "lambda_policy" {
    statement {
      sid = "Allow twitter poller to access s3"
      effect = "Allow"
      actions = ["s3:*"]
    }
}

resource "aws_iam_role" "lambda_execution_role" {
    name = "twitter-poller-role"
    assume_role_policy = data.aws_iam_policy_document.assume_role_multi_purpose.json

    tags = local.common_tags
}

resource "aws_iam_policy" "lambda_policy" {
    name = "twitter-poller-policy"
    policy = data.aws_iam_policy_document.lambda_policy.json

    tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
    role = aws_iam_role.lambda_execution_role.name
    policy_arn = aws_iam_policy.lambda_policy.arn
}

# End policy and role crap again
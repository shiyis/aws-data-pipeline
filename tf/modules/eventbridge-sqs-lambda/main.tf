# This is where we create the twitter-polling lambda function and the schedule to trigger it, as well as
# the sqs queue that acts as the go-between. Outputs include the arn of the lambda function so that it
# can be included in policies.
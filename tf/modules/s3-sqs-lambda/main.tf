# Takes in the bucket that data is stored in, creates bucket policy, sqs queue, lambda function. 
# Lambda function will be the one that processes data and feeds it to sagemaker. We may not need 
# this, considering sagemaker accesses the s3 bucket directly.

# Important note: This is where we will create and attach the bucket policy, so anything that needs access to s3
# needs to be included in the variables of this module
variable "bucket_name" {
    type = string
    description = "Name of the bucket data is stored in"
}

variable "sagemaker_arn" {
    type = string
    description = "ARN of sagemaker instance to give permissions in bucket policy"
}

variable "twitter_lambda_function_arn" {
    type = string
    description = "The ARN of the lambda function that scrapes twitter"
}
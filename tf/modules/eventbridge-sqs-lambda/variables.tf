variable "bucket" {
    type = string
    description = "The bucket to drop data into"
}

variable "lambda_schedule" {
    type = string
    description = "A cron expression that tells the lambda function when to activate"
}
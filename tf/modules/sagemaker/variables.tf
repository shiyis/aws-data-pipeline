variable "bucket_name" {
    type = string
    description = "The bucket for data storage"
}

variable "instance_type" {
    type = string
    description = "Instance type for sagemaker notebook instance"
    default = "ml.t3.medium"
}

variable "on_create" {
    type = string
    description = "A shell script to run on creation of the instance"
}

variable "on_start" {
    type = string
    description = "A shell script to run when the instance is started from a stop"
}

variable "subnet_id" {
    type = string
    description = "The subnet to place our sagemaker instance in."
}

variable "common_tags" {
    type = map(string)
    description = "Tags to attach to all resources"
}

variable "vpc_id" {
    type = string
    description = "The vpc to place our instance in (must contain provided subnet_id)"
}
variable "bucket_name" {
    type = string
    description = "The bucket for data storage"
}

variable "instance_type" {
    type = string
    description = "Instance type for sagemaker notebook instance"
    default = "ml.t3.medium"
}
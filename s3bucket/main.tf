#Create S3 bucket w/ versioning
resource "random_pet" "this" {
  length = 3
}
resource "aws_s3_bucket" "bucket" {
  bucket = random_pet.this.id
}

resource "aws_s3_bucket_notification" "bucket_main" {
  bucket = aws_s3_bucket.bucket.id
  acl = "private"
  versioning{
    enabled = true
  }
}
output "name" {
  value = aws_s3_bucket.this.bucket
  description = "The name of the AWS S3 bucket"
}

output "arn" {
  value = aws_s3_bucket.this.arn
  description = "The ARN of the bucket"
}

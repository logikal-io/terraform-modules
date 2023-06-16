output "name" {
  value = var.versioning ? aws_s3_bucket_versioning.this.bucket : aws_s3_bucket.this.bucket
  description = "The name of the AWS S3 bucket"
}

output "arn" {
  value = aws_s3_bucket.this.arn
  description = "The ARN of the bucket"
}

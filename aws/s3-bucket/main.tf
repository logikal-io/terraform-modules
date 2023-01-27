terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.41"
    }
  }
}

data "aws_region" "current" {}

resource "aws_s3_bucket" "this" {
  bucket = "${var.name}-${data.aws_region.current.name}-${var.suffix}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aws_managed" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.expire_days != null ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    id = "expire"
    abort_incomplete_multipart_upload {
      days_after_initiation = var.expire_days
    }
    expiration {
      days = var.expire_days
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl = var.public ? "public-read" : "private"
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls = !var.public
  block_public_policy = !var.public
  ignore_public_acls = !var.public
  restrict_public_buckets = !var.public
}

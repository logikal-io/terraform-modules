terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.31"
    }
  }
}

data "aws_region" "current" {}

resource "aws_s3_bucket" "this" {
  bucket = "${var.name}-${data.aws_region.current.name}-${var.suffix}"

  tags = var.tags
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
    id = "expire-at-day-${var.expire_days}"
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
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

# Resource to avoid error "AccessControlListNotSupported: The bucket does not allow ACLs"
resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls = !var.public
  block_public_policy = !var.public
  ignore_public_acls = !var.public
  restrict_public_buckets = !var.public
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning ? "Enabled" : "Disabled"
  }
}

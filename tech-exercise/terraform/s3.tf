provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "public_internal_bucket" {
  bucket = var.bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.public_internal_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.public_internal_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.public_internal_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowGetFromMyIP",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3*",
        Resource  = "${aws_s3_bucket.public_internal_bucket.arn}/*",
        Condition = {
          IpAddress = {
            "aws:SourceIp" = "${local.management_ip_cidr}"
          }
        }
      },
      {
        Sid       = "AllowVPCeAccess",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:*",
        Resource = [
          "${aws_s3_bucket.public_internal_bucket.arn}",
          "${aws_s3_bucket.public_internal_bucket.arn}/*"
        ],
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = module.vpc.s3_endpoint.id
          }
        }
      }
    ]
  })
}

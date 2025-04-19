resource "aws_s3_bucket" "public_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.public_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.public_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_cors_configuration" "public_bucket_cors" {
  bucket = aws_s3_bucket.public_bucket.id

  cors_rule {
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  version = "2012-10-17"

  statement {
    sid     = "AllowFullAccessFromMyIP"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.public_bucket.arn,
      "${aws_s3_bucket.public_bucket.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = [local.management_ip_cidr]
    }
  }

  statement {
    sid    = "AllowVPCeAccess"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.public_bucket.arn,
      "${aws_s3_bucket.public_bucket.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = [module.vpc_endpoints.endpoints["s3"].id]
    }
  }

  statement {
    sid    = "AllowPublicReadAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.public_bucket.arn,
      "${aws_s3_bucket.public_bucket.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.public_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.public_bucket.id
  key          = "index.html"
  content_type = "text/html"

  content = templatefile("${path.module}/html/index.html", {
    bucket = var.bucket_name,
    region = var.region,
    prefix = "backups/mysql/"
  })

  etag = md5(templatefile("${path.module}/html/index.html", {
    bucket = var.bucket_name,
    region = var.region,
    prefix = "backups/mysql/"
  }))
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.public_bucket.id
  key          = "error.html"
  source       = "${path.module}/html/error.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/html/error.html")
}

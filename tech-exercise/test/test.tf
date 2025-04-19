# Test config
resource "aws_s3_bucket" "test" {
  bucket        = "zantinelli-test"
  force_destroy = true
}

output "test_bucket_name" {
  value = aws_s3_bucket.test.bucket_domain_name
  description = "Test S3 bucket name"
}


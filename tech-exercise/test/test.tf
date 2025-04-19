resource "aws_s3_bucket" "test_bucket" {
  bucket        = zantinelli-test
  force_destroy = true
}


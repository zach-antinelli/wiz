data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  iam_user   = data.aws_caller_identity.current.arn
}

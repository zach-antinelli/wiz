data "aws_caller_identity" "current" {}

data "http" "public_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  account_id         = data.aws_caller_identity.current.account_id
  iam_user           = data.aws_caller_identity.current.arn
  management_ip_cidr = "${chomp(data.http.public_ip.response_body)}/32"
}

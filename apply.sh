#!/usr/bin/env bash

export ACM_ARN="arn:aws:acm:us-west-2:913524944844:certificate/15687ef0-dad8-4b2c-874a-9e4f50c9bbad"
export DOMAIN="wiz.zachantinelli.me"

[ "$1" = "prod" ] && ACTION="apply" || ACTION="delete"

envsubst < whoami.yaml | kubectl "$ACTION" -f -
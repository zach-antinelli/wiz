#!/usr/bin/env bash

export ACM_ARN=""
export ALB_DNS=""
export IMAGE_URI=""

[ "$1" = "-d" ] && ACTION="delete" || ACTION="apply"

envsubst <whoami.yaml | kubectl "$ACTION" -f -

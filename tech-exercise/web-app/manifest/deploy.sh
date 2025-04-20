#!/usr/bin/env bash

export APP_NAME
export ACM_ARN=""
export ALB_DNS=""
export IMAGE_URI=""

[ "$1" = "-d" ] && ACTION="delete" || ACTION="apply"

envsubst <gensel.yml | kubectl "$ACTION" -f -

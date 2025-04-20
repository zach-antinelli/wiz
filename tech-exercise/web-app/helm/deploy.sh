#!/usr/bin/env bash

export APP_NAME=""
export APP_IMAGE=""
export APP_SG_ID=""
export APP_CERT_ARN=""
export CONTAINER_PORT="8080"
export SUBNET_ID_US_WEST_2A=""
export SUBNET_ID_US_WEST_2B=""
export SUBNET_ID_US_WEST_2C=""

[ "$1" = "-d" ] && ACTION="delete" || ACTION="apply"

envsubst <gensen.yml | kubectl "$ACTION" -f -
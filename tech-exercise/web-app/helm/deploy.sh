#!/usr/bin/env bash

export APP_NAME="gensen"
export APP_IMAGE="986008f7d99e13cec8da121b3db548a0bad054cd"
export APP_SG_ID="sg-07e2f1c9000aad734"
export APP_CERT_ARN="arn:aws:acm:us-west-2:688567300039:certificate/87685d1b-deda-4053-b2de-d5e2271b3d06"
export CONTAINER_PORT="8080"
export PRIVATE_SUBNET_ID_US_WEST_2A="subnet-0147dbecbb97e05ae"
export PRIVATE_SUBNET_ID_US_WEST_2B="subnet-0102341480e0db7fd"
export PRIVATE_SUBNET_ID_US_WEST_2C="subnet-069e18dfa12bf6391"
export PUBLIC_SUBNETS="subnet-05e4ea56f16e0a44a,subnet-0d7c44c8ae7bbe65d,subnet-0d06dcf54306d5213"

[ "$1" = "-d" ] && ACTION="delete" || ACTION="apply"

if [ "$ACTION" == "apply" ]; then
  kubectl create ns "$APP_NAME"
fi

#envsubst <"${APP_NAME}.yaml" > out.yaml; exit
envsubst <"${APP_NAME}.yaml" | kubectl -n "$APP_NAME" "$ACTION" -f -

if [ "$ACTION" == "delete" ]; then
  kubectl delete ns "$APP_NAME"
fi
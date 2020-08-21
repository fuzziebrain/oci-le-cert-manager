#!/usr/bin/env bash

DIRNAME=$(dirname ${0})
COMMAND=${1:-generate}
ENV_FILE=${2:-}

docker run --rm \
  -p 8000:80 \
  --env-file ${ENV_FIEL} \
  -v $DIRNAME/letsencrypt:/etc/letsencrypt:z \
  -v $DIRNAME/.oci:/root/.oci \
  oci-le-cert-manager \
  cert-manager ${COMMAND}

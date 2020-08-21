#!/usr/bin/env bash

DIRNAME=$(dirname ${0})
COMMAND=${1:-generate}
ENV_FILENAME=${2:-}

docker run --rm \
  -p 8000:80 \
  --env-file ${DIRNAME}/${ENV_FILENAME} \
  -v $DIRNAME/letsencrypt:/etc/letsencrypt:z \
  -v $DIRNAME/.oci:/root/.oci \
  oci-le-cert-manager \
  cert-manager ${COMMAND}

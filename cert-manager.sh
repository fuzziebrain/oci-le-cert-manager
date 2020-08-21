#!/usr/bin/env bash

docker run --rm \
  -p 8000:80 \
  --env-file $PWD/domain.env \
  -v $PWD/letsencrypt:/etc/letsencrypt:z \
  -v $PWD/.oci:/root/.oci \
  oci-le-cert-manager \
  cert-manager ${1:-generate}

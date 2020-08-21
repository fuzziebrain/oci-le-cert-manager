#!/usr/bin/env bash

docker run --rm -it \
  -p 8000:80 \
  -e "USE_STAGING_YN=Y" \
  --env-file $PWD/domain.env \
  -v $PWD/letsencrypt:/etc/letsencrypt:z \
  -v $PWD/.oci:/root/.oci \
  -v $PWD/app:/root/app \
  oci-le-cert-manager \
  bash

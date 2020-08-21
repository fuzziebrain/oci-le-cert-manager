FROM oraclelinux:7-slim as base
LABEL MAINTAINER="Adrian Png <adrian.png@fuzziebrain.com>"

ENV LC_ALL=en_US.utf-8 \
    LANG=en_US.utf-8 \
    OCI_CLI_AUTH=instance_principal \
    DOMAIN=example.com \
    EMAIL=johndoe@example.com \
    LB_OCID=ocid1.loadbalancer.oc1... \
    LISTENER_NAME=https_listener \
    WAF_OCID=ocid1.waaspolicy.oc1... \
    DEPLOY_TARGET=LB \
    DRY_RUN=N

COPY ./app/requirements.txt /tmp/

RUN yum install -y \
        vi \
        jq \
        python3 \
        python3-pip && \
    rm -rf /var/cache/yum && \
    pip3 install -r /tmp/requirements.txt && \
    rm -f /tmp/requirements.txt

###############################################################################
FROM base

COPY ./app/cert-manager ./app/deploy-cert-to-lb /usr/local/bin/

RUN cd /usr/local/bin && \
    chmod a+x cert-manager deploy-cert-to-lb

WORKDIR /root

#VOLUME ["/etc/letsencrypt"]

CMD ["/usr/local/bin/cert-manager"]

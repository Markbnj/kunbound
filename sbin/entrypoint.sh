#!/bin/bash

ROOT_TRUST_DIR=/var/lib/unbound
ROOT_TRUST_ANCHOR_FILE=${ROOT_TRUST_DIR}/root.key
UNBOUND_IP=127.0.0.1

mkdir -p ${ROOT_TRUST_DIR}
chown unbound:unbound ${ROOT_TRUST_DIR}
unbound-anchor -a $ROOT_TRUST_ANCHOR_FILE -v
chown unbound:unbound $ROOT_TRUST_ANCHOR_FILE
exec unbound -c /etc/unbound/unbound.conf

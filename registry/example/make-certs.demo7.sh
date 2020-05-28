#!/bin/sh

[ -f ca-key.pem ] || openssl genrsa -out ca-key.pem 4096
openssl req -new -x509 -days 365 -subj "/CN=Local CA" -key ca-key.pem -sha256 -out ca.pem
[ -f reg-key.pem ] || openssl genrsa -out reg-key.pem 4096
[ -f reg.csr ] || openssl req -new -subj "/CN=Registry" -key reg-key.pem -out reg.csr
echo "subjectAltName = DNS:hub-cache,DNS:gitlab-cache" >reg.ext
openssl x509 -req -days 365 -in reg.csr -extfile reg.ext -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out reg.pem




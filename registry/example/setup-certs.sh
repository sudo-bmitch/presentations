#/bin/sh

# lookup the internal interface IP address
#ip_internal=$(ip route get 10.0.0.0 | awk 'NR==1 {print $NF}')

# lookup the internet interface IP address
#ip_internet=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')

#cert_san="IP:127.0.0.1,IP:${ip_internal},IP:${ip_internet},DNS:$(hostname),DNS:localhost"

certdir="certs"
cert_host="registry"
cert_san="DNS:localhost,DNS:$(hostname)"
for ip in $(ip a | grep inet | awk '{print $2}' | cut -f1 -d/); do
  cert_san="${cert_san},IP:$ip"
done

if [ ! -d "$certdir" ]; then
  mkdir -p "$certdir"
fi

# setup a CA key
if [ ! -f "$certdir/ca-key.pem" ]; then
  openssl genrsa -out "${certdir}/ca-key.pem" 4096
fi

# setup a CA cert
openssl req -new -x509 -days 365 \
  -subj "/CN=Local CA" \
  -key "${certdir}/ca-key.pem" \
  -sha256 -out "${certdir}/ca.pem"

# setup a host key
if [ ! -f "${certdir}/key.pem" ]; then
  openssl genrsa -out "${certdir}/key.pem" 2048
fi

# create a signing request
extfile="${certdir}/extfile"
openssl req -subj "/CN=${cert_host}" -new -key "${certdir}/key.pem" \
   -out "${certdir}/${cert_host}.csr"
echo "subjectAltName = ${cert_san}" >${extfile}

# create the host cert
openssl x509 -req -days 365 \
   -in "${certdir}/${cert_host}.csr" -extfile "${certdir}/extfile" \
   -CA "${certdir}/ca.pem" -CAkey "${certdir}/ca-key.pem" -CAcreateserial \
   -out "${certdir}/cert.pem"

# cleanup
if [ -f "${certdir}/${cert_host}.csr" ]; then
        rm -f -- "${certdir}/${cert_host}.csr"
fi
if [ -f "${extfile}" ]; then
        rm -f -- "${extfile}"
fi



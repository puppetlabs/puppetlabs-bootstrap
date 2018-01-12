#!/bin/sh

validate() {
  if $(echo $1 | grep \' > /dev/null) ; then
    echo "Single-quote is not allowed in arguments" > /dev/stderr
    exit 1
  fi
}

master=$PT_master
cacert_content=$PT_cacert_content
certname=$PT_certname
alt_names=$PT_dns_alt_names

validate $certname
validate $alt_names

if [ -n "${certname?}" ] ; then
  certname_arg="agent:certname='${certname}' "
fi
if [ -n "${alt_names?}" ] ; then
  alt_names_arg="agent:dns_alt_names='${alt_names}' "
fi

set -e

[ -d /etc/puppetlabs/puppet/ssl/certs ] || mkdir -p /etc/puppetlabs/puppet/ssl/certs
if [ -n "${cacert_content?}" ]; then
  echo "${cacert_content}" > /etc/puppetlabs/puppet/ssl/certs/ca.pem
  curl_arg="--cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem"
else
  curl_arg="-k"
fi

curl -s ${curl_arg?} https://${master}:8140/packages/current/install.bash | bash -s ${certname_arg}${alt_names_arg} && echo "Installed"

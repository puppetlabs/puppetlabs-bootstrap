#!/bin/sh

validate() {
  if $(echo $1 | grep \' > /dev/null) ; then
    echo "Single-quote is not allowed in arguments" > /dev/stderr
    exit 1
  fi
}

master="$PT_master"
cacert_content="$PT_cacert_content"
certname="$PT_certname"
alt_names="$PT_dns_alt_names"
custom_attribute="$PT_custom_attribute"
extension_request="$PT_extension_request"
jq_missing="jq is required to parse CSR custom attributes or extension requests"

validate $certname
validate $alt_names

if [ -n "${certname?}" ] ; then
  certname_arg="agent:certname='${certname}' "
fi
if [ -n "${alt_names?}" ] ; then
  alt_names_arg="agent:dns_alt_names='${alt_names}' "
fi
if [ -n "${custom_attribute?}" ] ; then
  command -v jq >/dev/null 2>&1 || { echo $jq_missing >&2; exit 1; }
  mapping='$x | map("custom_attributes:"+.)|join(" ")'
  custom_attributes_arg=$(jq -n -r --argjson x $custom_attribute $mapping)
fi
if [ -n "${extension_request?}" ] ; then
  command -v jq >/dev/null 2>&1 || { echo $jq_missing >&2; exit 1; }
  mapping='$x | map("extension_requests:"+.)|join(" ")'
  extension_requests_arg=$(jq -n -r --argjson x $extension_request $mapping)
fi

set -e

[ -d /etc/puppetlabs/puppet/ssl/certs ] || mkdir -p /etc/puppetlabs/puppet/ssl/certs
if [ -n "${cacert_content?}" ]; then
  echo "${cacert_content}" > /etc/puppetlabs/puppet/ssl/certs/ca.pem
  curl_arg="--cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem"
else
  curl_arg="-k"
fi

curl -s ${curl_arg?} https://${master}:8140/packages/current/install.bash | bash -s ${certname_arg}${alt_names_arg}${custom_attributes_arg}${extension_requests_arg} && echo "Installed"

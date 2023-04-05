#!/bin/bash

validate() {
  if $(echo $1 | grep \' > /dev/null) ; then
    echo "Single-quote is not allowed in arguments" > /dev/stderr
    exit 1
  fi
}

convert_array_string() {
  array_string=$2
  array_string=${array_string// /}
  array_string=${array_string//,/ }

  array_string=${array_string##[}
  array_string=${array_string%]}

  eval array=($array_string)

  for item in "${array[@]}"
  do
    result="${result} $1:$item "
  done
  echo $result
}

convert_array_string_puppet_conf() {
  array_string=$2
  array_string=${array_string// /}
  array_string=${array_string//,/ }

  array_string=${array_string##[}
  array_string=${array_string%]}

  eval array=($array_string)

  for item in "${array[@]}"
  do
    result="$item \\"
  done
  final_result="${1} ${result}"
  echo $final_result
}


master="$PT_master"
cacert_content="$PT_cacert_content"
certname="$PT_certname"
environment="$PT_environment"
set_noop="$PT_set_noop"
alt_names="$PT_dns_alt_names"
custom_attribute="$PT_custom_attribute"
extension_request="$PT_extension_request"
puppet_conf="$PT_puppet_conf_settings"

validate $certname
validate $environment
validate $set_noop
validate $alt_names

if [ -n "${certname?}" ] ; then
  certname_arg="agent:certname='${certname}' "
fi
if [ -n "${environment?}" ] ; then
  environment_arg="agent:environment='${environment}' "
fi
if [ -n "${set_noop?}" ] ; then
  set_noop_arg="agent:noop=${set_noop} "
fi
if [ -n "${alt_names?}" ] ; then
  alt_names_arg="agent:dns_alt_names='${alt_names}' "
fi
if [ -n "${custom_attribute?}" ] ; then
  custom_attributes_arg="$(convert_array_string custom_attributes "${custom_attribute}") "
fi
if [ -n "${extension_request?}" ] ; then
  extension_requests_arg="$(convert_array_string extension_requests "${extension_request}") "
fi
if [ -n "${puppet_conf?}" ] ; then
  puppet_conf_arg="$(convert_array_string -s "${puppet_conf}") "
fi

set -e

[ -d /etc/puppetlabs/puppet/ssl/certs ] || mkdir -p /etc/puppetlabs/puppet/ssl/certs
if [ -n "${cacert_content?}" ]; then
  echo "${cacert_content}" > /etc/puppetlabs/puppet/ssl/certs/ca.pem
  curl_arg="--cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem"
else
  curl_arg="-k"
fi

echo "bash /tmp/install.bash ${certname_arg}${environment_arg}${set_noop_arg}${alt_names_arg}${custom_attributes_arg}${extension_requests_arg}${puppet_conf_arg}" > /tmp/command

if curl ${curl_arg?} https://${master}:8140/packages/current/install.bash -o /tmp/install.bash; then
  if bash /tmp/install.bash ${certname_arg}${environment_arg}${set_noop_arg}${alt_names_arg}${custom_attributes_arg}${extension_requests_arg}${puppet_conf_arg}; then
    echo "Installed"
    exit 0
  else
    echo "Failed to run install.bash"
    exit 1
  fi
else
  echo "Failed to download install.bash"
  exit 1
fi

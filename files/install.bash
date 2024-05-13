#! /bin/bash
set -u
set -e


#! /bin/bash

PUPPET_CONF_DIR="/etc/puppetlabs/puppet"
PUPPET_BIN_DIR="/opt/puppetlabs/bin"
PUPPET_INTERNAL_BIN_DIR="/opt/puppetlabs/puppet/bin"
DEFAULT_CA_CERT="/etc/puppetlabs/puppet/ssl/certs/ca.pem"

# Create global variables to track the desired state of the puppet service.
# Default state will be running and enabled unless changed in the
# custom_puppet_configuration function. These variables are used in the
# manage_puppet_agent function after installation.
PUPPET_SERVICE_ENSURE='running'
PUPPET_SERVICE_ENABLE='true'
PUPPET_SERVICE_DEBUG=''

fail() { echo >&2 "$@"; exit 1; }
cmd()  { hash "$1" >&/dev/null; } # portable 'which'

if [ -z "${CLEANUP[*]+x}" ]; then
  declare -a CLEANUP
  CLEANUP=()
fi

cleanup() {
 if (( ${#CLEANUP[@]} )); then
   for cmd in "${CLEANUP[@]}"
   do
     $cmd
   done
 fi
}

trap cleanup EXIT

cleanup_add_cmd() {
  CLEANUP=("${CLEANUP[@]-}" "$1")
}

trace() {
  ${FRICTIONLESS_TRACE:-false}
}

puppet_installed() {
  if [ -x "${PUPPET_BIN_DIR}/puppet" ]; then
    return 0
  else
    return 1
  fi
}

pxp_present() {
    if [ -x "${PUPPET_INTERNAL_BIN_DIR}/pxp-agent" ]; then
        return 0
    else
        return 1
    fi
}

# Echo back either the AIO puppet bin dir path, or PE 3.x pe-agent
# puppet bin dir.
puppet_bin_dir() {
    if [ -e "${PUPPET_BIN_DIR}" ]; then
        t_puppet_bin_dir="${PUPPET_BIN_DIR}"
    else
        t_puppet_bin_dir=/opt/puppet/bin
    fi
    echo "${t_puppet_bin_dir}"
}

mktempfile() {
  if cmd mktemp; then
    if [ "osx" = "${PLATFORM_NAME}" ]; then
      mktemp -t installer
    else
      mktemp
    fi
  else
    echo "/tmp/puppet-enterprise-installer.XXX-${RANDOM}"
  fi
}

custom_puppet_configuration() {
  # Parse optional pre-installation configuration of Puppet settings via
  # command-line arguments. Arguments should be one of the valid flags,
  # or else a section/setting/value directive.
  #
  # Valid Flags:
  #
  # --puppet-service-ensure <value>
  # --puppet-service-enable <value>
  #
  # Section / Setting / Value directives:
  #
  #   <section>:<setting>=<value>
  #
  # There are four valid section settings in puppet.conf: "main", "master",
  # "agent", "user". If you provide valid setting and value for one of these
  # four sections, it will end up in <confdir>/puppet.conf.
  #
  # There are two sections in csr_attributes.yaml: "custom_attributes" and
  # "extension_requests". If you provide valid setting and value for one
  # of these two sections, it will end up in <confdir>/csr_attributes.yaml.
  #
  # note:Custom Attributes are only present in the CSR, while Extension
  # Requests are both in the CSR and included as X509 extensions in the
  # signed certificate (and are thus available as "trusted facts" in Puppet).
  #
  # Regex is authoritative for valid sections, settings, and values.  Any
  # non-flag input that fails regex will trigger this script to fail with error
  # message.
  regex='^(main|master|agent|user|custom_attributes|extension_requests):([^=]+)=(.*)$'
  declare -a attr_array
  declare -a extn_array

  while (( "$#" )); do
    if [[ $1 == '--puppet-service-ensure' ]]; then
      shift; PUPPET_SERVICE_ENSURE="$1"
    elif [[ $1 == '--puppet-service-enable' ]]; then
      shift; PUPPET_SERVICE_ENABLE="$1"
    elif [[ $1 == '--puppet-service-debug' ]]; then
      PUPPET_SERVICE_DEBUG='--debug'
    elif [[ $1 =~ $regex ]]; then
      section=${BASH_REMATCH[1]}
      setting=${BASH_REMATCH[2]}
      value=${BASH_REMATCH[3]}
      case $section in
        custom_attributes)
          # Store the entry in attr_array for later addition to csr_attributes.yaml
          attr_array=("${attr_array[@]}" "${setting}: '${value}'")
          ;;
        extension_requests)
          # Store the entry in extn_array for later addition to csr_attributes.yaml
          extn_array=("${extn_array[@]}" "${setting}: '${value}'")
          ;;
        *)
          # Set the specified entry in puppet.conf
          "${PUPPET_BIN_DIR}/puppet" config set "$setting" "$value" --section "$section"
      esac
    else
      fail "Unable to interpret argument: '${1}'. Expected flag or '<section>:<setting>=<value>' matching regex: '${regex}'"
    fi

    shift
  done

  # If the the length of the attr_array or extn_array is greater than zero, it
  # means we have settings, so we'll create the csr_attributes.yaml file.
  if [[ ${#attr_array[@]} -gt 0 || ${#extn_array[@]} -gt 0 ]]; then
    mkdir -p "${PUPPET_CONF_DIR}"
    echo '---' > "${PUPPET_CONF_DIR}/csr_attributes.yaml"

    if [[ ${#attr_array[@]} -gt 0 ]]; then
      echo 'custom_attributes:' >> "${PUPPET_CONF_DIR}/csr_attributes.yaml"
      for ((i = 0; i < ${#attr_array[@]}; i++)); do
        echo "  ${attr_array[i]}" >> "${PUPPET_CONF_DIR}/csr_attributes.yaml"
      done
    fi

    if [[ ${#extn_array[@]} -gt 0 ]]; then
      echo 'extension_requests:' >> "${PUPPET_CONF_DIR}/csr_attributes.yaml"
      for ((i = 0; i < ${#extn_array[@]}; i++)); do
        echo "  ${extn_array[i]}" >> "${PUPPET_CONF_DIR}/csr_attributes.yaml"
      done
    fi
  fi
}

ensure_link() {
  "${PUPPET_BIN_DIR}/puppet" resource file "${1}" ensure=link target="${2}"
}

ensure_agent_links() {
  target_path="/usr/local/bin"

  if mkdir -p "${target_path}" && [ -w "${target_path}" ]; then
    for bin in facter puppet pe-man hiera; do
      ensure_link "${target_path}/${bin}" "${PUPPET_BIN_DIR}/${bin}"
    done
  else
    echo "!!! WARNING: ${target_path} is inaccessible; unable to create convenience symlinks for puppet, hiera, facter and pe-man.  These executables may be found in ${PUPPET_BIN_DIR}." 1>&2
  fi
}

# Detected existing installation? Return y if true, else n
is_upgrade() {
  if puppet_installed; then
    echo "y"
  else
    echo "n"
  fi
}

# Sets server, certname and any custom puppet.conf flags passed in to the script
puppet_config_set() {
  "${PUPPET_BIN_DIR}/puppet" config set server ip-10-8-0-168.ap-southeast-2.compute.internal --section main
  "${PUPPET_BIN_DIR}/puppet" config set certname "$("${PUPPET_BIN_DIR}/facter" fqdn | "${PUPPET_INTERNAL_BIN_DIR}/ruby" -e 'puts STDIN.read.downcase')" --section main
  custom_puppet_configuration "$@"

  # To ensure the new config settings take place and to work around differing OS behaviors on recieving a service start command while running
  # (on nix it triggers a puppet run, on osx it does nothing), stop the service before attempting to manage anything else.
  stop_puppet_agent
}

restart_puppet_agent() {
  "${PUPPET_BIN_DIR}/puppet" resource service puppet ensure=stopped
  "${PUPPET_BIN_DIR}/puppet" resource service puppet ensure=running enable=true
}

start_puppet_agent() {
  "${PUPPET_BIN_DIR}/puppet" resource service puppet ensure=running enable=true
}

stop_puppet_agent() {
  "$(puppet_bin_dir)/puppet" resource service puppet ensure=stopped
  wait_for_puppet_lock
}

manage_puppet_agent() {
  # If the state of the puppet service should be changed from its default of running and enabled,
  # print a message that indicates we will be doing so.
  if [[ $PUPPET_SERVICE_ENSURE != "running" ]] || [[ $PUPPET_SERVICE_ENABLE != "true" ]]; then
    echo "Setting the puppet service to ensure=$PUPPET_SERVICE_ENSURE and enable=$PUPPET_SERVICE_ENABLE"
  fi

  "$(puppet_bin_dir)/puppet" resource ${PUPPET_SERVICE_DEBUG} service puppet ensure="$PUPPET_SERVICE_ENSURE" enable="$PUPPET_SERVICE_ENABLE"
}

pxp_agent_status() {
  output=$("$(puppet_bin_dir)/puppet" resource service pxp-agent 2> /dev/null)
  case ${output} in
    *ensure*=\>*running*)
      echo "running";;
    *)
      echo "stopped";;
  esac
}

ensure_service() {
    pkg=${1}
    state=${2}
    "$(puppet_bin_dir)/puppet" resource service "${pkg}" ensure="${state}"
    return $?
}

wait_for_puppet_lock() {
  t_puppet_run_lock=$("$(puppet_bin_dir)/puppet" agent --configprint agent_catalog_run_lockfile)
  while [ -f "${t_puppet_run_lock}" ]; do
      echo "Waiting for Agent run lock ${t_puppet_run_lock} to clear..."
      sleep 10
  done
}

require_tlsv1() {
  if [[ "$PLATFORM_RELEASE" == "5" && ("$PLATFORM_NAME" == "rhel" || "$PLATFORM_NAME" == "centos") ]]; then
    return
  elif [[ "$PLATFORM_RELEASE" == "10" && ($PLATFORM_NAME =~ solaris) ]]; then
    return
  fi
  false
}

# Returns 0 if the script has been explicitly flagged to use a local Puppet CA
# cert, or if we can find the Puppet primary server's ca cert on disk at
# /etc/puppetlabs/puppet/ssl/certs/ca.pem
use_puppet_master_ca_cert() {
  [ "${FRICTIONLESS_USE_PUPPET_CA:-false}" = "true" ] || [ -f $DEFAULT_CA_CERT ]
}

# Use curl to download the requested url and store it in the given file.
# Fallback to wget if curl is not present
# Raise an error if neither is present.
#
# tlsv1 is enforced.
#
# If /etc/puppetlabs/puppet/ssl/certs/ca.pem is present, this certificate will
# be used to verify the connection with the Puppet primary server. Otherwise
# validity of the server certificate will not be checked.
#
# Arguments:
#   1. source_url to download (required)
#   2. output_file to store it in locally.
#      *If not given, streams to stdout.*
#   3. additional_options to be expanded into the argument list
curl_or_wget() {
  local t_source_url=${1}
  local t_output_file=$2
  local t_additional_options=$3
  local t_cmd
  local t_ssl_options
  local t_output_option

  declare -a t_options

  if cmd curl; then
    t_cmd='curl'

    if use_puppet_master_ca_cert; then
      t_ssl_options="--cacert $DEFAULT_CA_CERT"
    elif curl_has_peer_verify_by_default; then
      # we need to disable it
      t_ssl_options="-k"
    else
      # older curl on AIX doesn't support -k, but running without peer
      # verification is the default behavior
      t_ssl_options="--tlsv1"
    fi
    if require_tlsv1; then
      t_ssl_options+=" --tlsv1"
    fi

    if [ -n "$t_output_file" ]; then
      t_output_option="-o ${t_output_file}"
    fi
  elif cmd wget; then
    # wget on AIX doesn't support SSL
    [ "$PLATFORM_NAME" = "aix" ] && fail "Unable to download installation materials without curl"

    t_cmd='wget'

    if use_puppet_master_ca_cert; then
      t_ssl_options="--ca-certificate=$DEFAULT_CA_CERT"
    else
      t_ssl_options="--no-check-certificate"
    fi
    if require_tlsv1; then
      t_ssl_options+=" --secure-protocol=TLSv1"
    fi

    if [ -n "$t_output_file" ]; then
      t_output_option="-O ${t_output_file}"
    else
      # to stdout
      t_output_option="-O -"
    fi
  else
    fail "Couldn't find curl or wget; unable to continue."
  fi

  # options are intentionaly unquoted so that they break into elements in the
  # options array
  # shellcheck disable=SC2206
  local t_options=($t_ssl_options $t_output_option $t_additional_options "$t_source_url" )

  trace && echo >&2 "+ $t_cmd" "${t_options[@]}"
  "$t_cmd" "${t_options[@]}"
  local t_err_code=$?

  if [ $t_err_code -ne 0 ]; then
    echo >&2 "E: '$t_cmd" "${t_options[@]}" "' failed (exit_code: $t_err_code)"
  fi

  return $t_err_code
}

# Makes a curl_or_wget call with the appropriate flag to silence output
# added in.
curl_or_wget_quietly() {
  local t_additional_options=$3

  if cmd curl; then
    t_additional_options="${t_additional_options} -s"
  else
    t_additional_options="${t_additional_options} --quiet"
  fi

  curl_or_wget "$1" "$2" "${t_additional_options}"
}

# In version 7.10.0 curl introduced the -k flag and performs peer
# certificate validation by default. If peer validation is performed by
# default the -k flag is necessary for this script to work. However, if curl
# is older than 7.10.0 the -k flag does not exist.
#
# Return 0 if the -k flag should be used.
curl_has_peer_verify_by_default() {
  curl_ver_regex='curl ([0-9]+)\.([0-9]+)\.([0-9]+)'
  [[ "$(curl -V 2>/dev/null)" =~ $curl_ver_regex ]]
  curl_majv="${BASH_REMATCH[1]-7}"  # Default to 7  if no match
  curl_minv="${BASH_REMATCH[2]-10}" # Default to 10 if no match
  if [[ "$curl_majv" -eq 7 && "$curl_minv" -le 9 ]] || [[ "$curl_majv" -lt 7 ]]; then
    return 1
  else
    return 0
  fi
}

# XXX Remove -- still used by aix template
curl_no_peer_verify() {
  curl_ver_regex='curl ([0-9]+)\.([0-9]+)\.([0-9]+)'
  [[ "$(curl -V 2>/dev/null)" =~ $curl_ver_regex ]]
  curl_majv="${BASH_REMATCH[1]-7}"  # Default to 7  if no match
  curl_minv="${BASH_REMATCH[2]-10}" # Default to 10 if no match
  if [[ "$curl_majv" -eq 7 && "$curl_minv" -le 9 ]] || [[ "$curl_majv" -lt 7 ]]; then
    curl_invocation="curl"
  else
    curl_invocation="curl -k"
  fi

  $curl_invocation "$@"
}

# Returns the http code returned by curl or wget attempting to reach the given url.
# (The file itself is not downloaded)
#
# Arguments:
#     1. t_url to touch (Required)
check_http_code() {
  local t_url="${1}"

  if cmd curl; then
    t_http_code=$(curl_or_wget "${t_url}" /dev/null "-s --head --write-out %{http_code}")
  elif cmd wget; then
    # Run wget and use awk to figure out the HTTP status.
    t_http_code=$(curl_or_wget "${t_url}" /dev/null '-S' 2>&1 | awk '/HTTP\/1.1/ { printf $2 }')
  fi
  echo "$t_http_code"
}

# Uses curl, or if not present, wget to download file from passed http url to a
# temporary location.
#
# Arguments
# 1. The url to download
# 2. The file to save it as
#
# Returns 0 for 200 http exit code, 1 for all other http exit codes
#
# May exit early if the underlying command fails.
download_from_url() {
    local t_url="${1}"
    local t_file="${2}"

    if cmd curl; then
        t_http_code="$(curl_or_wget_quietly "${t_url}" "${t_file}" "-L --write-out %{http_code}")"
    elif cmd wget; then
        # Run wget and use awk to figure out the HTTP status.
        # (Note that this unfortunately has the side effect of swallowing trace
        # of the wget command issued in curl_or_wget(), since wget sends http
        # info to stderr as well)
        t_http_code=$(curl_or_wget_quietly "${t_url}" "${t_file}" '-S' 2>&1 | awk '/HTTP\/1.1/ { printf $2 }')
    fi

    local t_err_code=$?
    if [ $t_err_code -ne 0 ]; then
        fail "Error code ${t_err_code} attempting to reach ${t_url}"
    fi

    if [ "${t_http_code}" == "200" ]; then
        return 0
    else
        return 1
    fi
}

supported_platform() {
  t_supported_platforms=()
  t_supported_platforms+=('el-6-i386')
  t_supported_platforms+=('el-6-x86_64')
  t_supported_platforms+=('el-7-x86_64')
  t_supported_platforms+=('el-8-x86_64')
  t_supported_platforms+=('el-8-aarch64')
  t_supported_platforms+=('el-8-ppc64le')
  t_supported_platforms+=('el-9-x86_64')
  t_supported_platforms+=('el-9-aarch64')
  t_supported_platforms+=('redhatfips-7-x86_64')
  t_supported_platforms+=('redhatfips-8-x86_64')
  t_supported_platforms+=('debian-10-amd64')
  t_supported_platforms+=('debian-11-amd64')
  t_supported_platforms+=('ubuntu-18.04-amd64')
  t_supported_platforms+=('ubuntu-18.04-aarch64')
  t_supported_platforms+=('ubuntu-20.04-amd64')
  t_supported_platforms+=('ubuntu-20.04-aarch64')
  t_supported_platforms+=('ubuntu-22.04-amd64')
  t_supported_platforms+=('ubuntu-22.04-aarch64')
  t_supported_platforms+=('sles-12-x86_64')
  t_supported_platforms+=('sles-15-x86_64')
  t_supported_platforms+=('fedora-36-x86_64')
  t_supported_platforms+=('solaris-10-i386')
  t_supported_platforms+=('solaris-10-sparc')
  t_supported_platforms+=('solaris-11-i386')
  t_supported_platforms+=('solaris-11-sparc')
  t_supported_platforms+=('aix-7.1-power')
  t_supported_platforms+=('osx-11-x86_64')
  t_supported_platforms+=('osx-11-arm64')
  t_supported_platforms+=('osx-12-x86_64')
  t_supported_platforms+=('osx-12-arm64')
  t_supported_platforms+=('osx-13-x86_64')
  t_supported_platforms+=('osx-13-arm64')
  
  local supported=1
  for platform in "${t_supported_platforms[@]}"; do
    if [[ "${1}" == "${platform}" ]]; then
      supported=0
      break
    fi
  done
  return $supported
}

bulk_pluginsync() {
  t_bulk_pluginsync_url="${1}"
  t_bulk_pluginsync_file=$(mktempfile)

  echo "bulk downloading plugins"
  download_from_url "${t_bulk_pluginsync_url}" "${t_bulk_pluginsync_file}" || return 1

  echo "extracting plugins"
  mkdir -p /opt/puppetlabs/puppet/cache
  pushd /opt/puppetlabs/puppet/cache > /dev/null || return 1
  gunzip -c "${t_bulk_pluginsync_file}" | tar -xf -
  popd > /dev/null || return 1
}

run_agent_install_from_url() {
    t_agent_install_url="${1}"

    t_install_file=$(mktempfile)

    cleanup_add_cmd 'rm '"${t_install_file}"

    if ! download_from_url "${t_agent_install_url}" "${t_install_file}"; then
        if supported_platform "${PLATFORM_TAG}"; then
            fail "The agent packages needed to support ${PLATFORM_TAG} are not present on your primary. \
    To add them, apply the pe_repo::platform::$(echo "${PLATFORM_TAG}" | tr - _ | tr -dc '[a-z][A-Z][0-9]_') class to your primary node and then run Puppet. \
    The required agent packages should be retrieved when puppet runs on the primary, after which you can run the install.bash script again."
        else
            fail "This method of agent installation is not supported for ${PLATFORM_TAG} in Puppet Enterprise v2021.7.6"
        fi
    fi

    bash "${t_install_file}" "${@: 2}" || fail "Error running install script ${t_install_file}"
}

# vim: ft=sh

#! /bin/bash

# Sets PLATFORM_NAME to a value that PE expects
#
# Arguments:
# PLATFORM_NAME
# RELEASE_FILE
#
# Side-effect:
# Modifies PLATFORM_NAME
function sanitize_platform_name() {
    # Sanitize name for unusual platforms
    case "${PLATFORM_NAME}" in
        redhatenterpriseserver | redhatenterpriseclient | redhatenterpriseas | redhatenterprisees | enterpriseenterpriseserver | redhatenterpriseworkstation | redhatenterprisecomputenode | oracleserver)
            PLATFORM_NAME=rhel
            ;;
        scientific | scientifics | scientificsl | oracle | ol | rocky | almalinux)
            PLATFORM_NAME=rhel
            ;;
        enterprise*)
            PLATFORM_NAME=centos
            ;;
        'suse linux' | sles_sap )
            PLATFORM_NAME=sles
            ;;
        amazonami | amzn)
            PLATFORM_NAME=amazon
            ;;
    esac

    if [ -r "${RELEASE_FILE:-}" ] && grep -E "Cumulus Linux" "${RELEASE_FILE}" &> /dev/null; then
        PLATFORM_NAME=cumulus
    fi
}

# Sets PLATFORM_RELEASE to a value that PE expects
#
# Arguments:
# PLATFORM_NAME
# PLATFORM_RELEASE
#
# Side-effect:
# Modifies PLATFORM_RELEASE
function sanitize_platform_release() {
    # Sanitize release for unusual platforms
    case "${PLATFORM_NAME}" in
        centos | rhel | sles | solaris)
            # Platform uses only number before period as the release,
            # e.g. "CentOS 5.5" is release "5"
            PLATFORM_RELEASE=$(echo -n "${PLATFORM_RELEASE}" | cut -d. -f1)
            ;;
        amazon)
            # This line will parse the image_name: image_name="amzn2-ami-hvm"
            # Amazon linux v1 will be similar to: image_name="amzn-ami-hvm"
            t_image_name=$(grep image_name /etc/image-id | cut -d\" -f2 | cut -d- -f1)
            if [ -z "$t_image_name" ]; then
                fail "Unable to parse Amazon Linux version info from /etc/image-id"
            else
                if [ "$t_image_name" == "amzn2" ]; then
                    PLATFORM_RELEASE=7
                else
                    PLATFORM_RELEASE=6
                fi
            fi
            ;;
        debian)
            # Platform uses only number before period as the release,
            # e.g. "Debian 6.0.1" is release "6"
            PLATFORM_RELEASE=$(echo -n "${PLATFORM_RELEASE}" | cut -d. -f1)
            if [ "${PLATFORM_RELEASE}" = "testing" ] ; then
                PLATFORM_RELEASE=7
            fi
            ;;
        cumulus)
            PLATFORM_RELEASE=$(echo -n "${PLATFORM_RELEASE}" | cut -d'.' -f'1,2')
            ;;
    esac
}

##############################################################################
# We need to know what the PE platform tag is for this node, which requires
# digging through a bunch of data to extract it.  This is currently the best
# mechanism available to do this, which is copied from the PE
# installer itself.

# shellcheck source=/dev/null
if [ -z "${PLATFORM_NAME:-""}" ] || [ -z "${PLATFORM_RELEASE:-""}" ]; then
    # https://www.freedesktop.org/software/systemd/man/os-release.html#Description
    # Try /etc/os-release first, then /usr/lib/os-release, then legacy pre-systemd methods
    if [ -f "/etc/os-release" ] || [ -f "/usr/lib/os-release" ]; then
        if [ -f "/etc/os-release" ]; then
            RELEASE_FILE="/etc/os-release"
        else
            RELEASE_FILE="/usr/lib/os-release"
        fi
        PLATFORM_NAME=$(source "${RELEASE_FILE}"; echo -n "${ID}")
        sanitize_platform_name
        PLATFORM_RELEASE=$(source "${RELEASE_FILE}"; echo -n "${VERSION_ID}")
        sanitize_platform_release

        # For some EL platforms we also support FIPS mode, which changes the platform name
        if [[ "$PLATFORM_NAME" == "rhel" || "$PLATFORM_NAME" == "centos" ]]; then
            if [ -f "/proc/sys/crypto/fips_enabled" ]; then
                t_fips_status="$(cat /proc/sys/crypto/fips_enabled)"
                if [ "$t_fips_status" == "1" ]; then
                    PLATFORM_NAME='redhatfips'
                fi
            fi
        fi
    # Try identifying using lsb_release.  This takes care of Ubuntu
    # (lsb-release is part of ubuntu-minimal).
    elif type lsb_release > /dev/null 2>&1; then
        t_prepare_platform=$(lsb_release -icr 2>&1)

        PLATFORM_NAME="$(echo -n "${t_prepare_platform}" | grep -E '^Distributor ID:' | cut -s -d: -f2 | sed 's/[[:space:]]//' | tr '[:upper:]' '[:lower:]')"
        sanitize_platform_name

        # Release
        PLATFORM_RELEASE="$(echo -n "${t_prepare_platform}" | grep -E '^Release:' | cut -s -d: -f2 | sed 's/[[:space:]]//g')"
        sanitize_platform_release
    elif [ "$(uname -s)" = "Darwin" ]; then
        PLATFORM_NAME="osx"
        t_platform_release_major="$(/usr/bin/sw_vers -productVersion | cut -d'.' -f1)"
        # For 10, we want x.y. For 11+, we only want the x.
        if ((t_platform_release_major > 10)); then
            t_platform_release=$t_platform_release_major
        else
            t_platform_release="$(/usr/bin/sw_vers -productVersion | cut -d'.' -f1,2)"
        fi
        PLATFORM_RELEASE="${t_platform_release}"
    # Test for Solaris.
    elif [ "$(uname -s)" = "SunOS" ]; then
        PLATFORM_NAME="solaris"
        t_platform_release="$(uname -r)"
        # JJM We get back 5.10 but we only care about the right side of the decimal.
        PLATFORM_RELEASE="${t_platform_release##*.}"
    elif [ "$(uname -s)" = "AIX" ] ; then
        PLATFORM_NAME="aix"
        PLATFORM_RELEASE="7.1"

    # Test for RHEL variant. RHEL, CentOS, OEL
    elif [ -f /etc/redhat-release ] && [ -r /etc/redhat-release ] && [ -s /etc/redhat-release ]; then
        # Oracle Enterprise Linux 5.3 and higher identify the same as RHEL
        if grep -qi 'red hat enterprise' /etc/redhat-release; then
            PLATFORM_NAME=rhel
        elif grep -qi 'centos' /etc/redhat-release; then
            PLATFORM_NAME=centos
        elif grep -qi 'scientific' /etc/redhat-release; then
            PLATFORM_NAME=rhel
        elif grep -qi 'rocky' /etc/redhat-release; then
            PLATFORM_NAME=rhel
        elif grep -qi 'alma' /etc/redhat-release; then
            PLATFORM_NAME=rhel
        elif grep -qi 'fedora' /etc/redhat-release; then
            PLATFORM_NAME='fedora'
        fi
        # Release - take first digits after ' release ' only.
        PLATFORM_RELEASE="$(sed 's/.*\ release\ \([[:digit:]]\+\).*/\1/g;q' /etc/redhat-release)"

    # Test for Debian releases
    elif [ -f /etc/debian_version ] && [ -r /etc/debian_version ] && [ -s /etc/debian_version ]; then
        t_prepare_platform__debian_version_file="/etc/debian_version"

        if grep -qE '^[[:digit:]]' "${t_prepare_platform__debian_version_file}"; then
            PLATFORM_NAME=debian
            PLATFORM_RELEASE="$(sed 's/\..*//' "${t_prepare_platform__debian_version_file}")"
        elif grep -qE '^wheezy' "${t_prepare_platform__debian_version_file}"; then
            PLATFORM_NAME=debian
            PLATFORM_RELEASE="7"
        fi
    elif [ -f /etc/SuSE-release ] && [ -r /etc/SuSE-release ]; then
        t_prepare_platform__suse_version=$(cat /etc/SuSE-release)

        if echo -n "${t_prepare_platform__suse_version}" | grep -E 'Enterprise Server'; then
            PLATFORM_NAME=sles
            t_version=$(grep VERSION /etc/SuSE-release | sed 's/^VERSION = \(\d*\)/\1/')
            PLATFORM_RELEASE="${t_version}"
        fi
    elif [ -f /etc/system-release ]; then
        if grep -qi 'amazon linux' /etc/system-release; then
          PLATFORM_NAME=amazon
          sanitize_platform_release
        else
            fail "$(cat /etc/system-release) is not a supported platform for Puppet Enterprise v2021.7.6
                    Please visit http://links.puppetlabs.com/puppet_enterprise_${PE_LINK_VER}_platform_support to request support for this platform."

        fi
    elif [ -z "${PLATFORM_NAME:-""}" ]; then
        fail "$(uname -s) is not a supported platform for Puppet Enterprise v2021.7.6
            Please visit http://links.puppetlabs.com/puppet_enterprise_${PE_LINK_VER}_platform_support to request support for this platform."
    fi
fi

if [ -z "${PLATFORM_NAME:-""}" ] || [ -z "${PLATFORM_RELEASE:-""}" ]; then
    fail "Unknown platform"
fi

# Architecture
if [ -z "${PLATFORM_ARCHITECTURE:-""}" ]; then
    case "${PLATFORM_NAME}" in
        solaris | aix )
            PLATFORM_ARCHITECTURE="$(uname -p)"
            if [ "${PLATFORM_ARCHITECTURE}" = "powerpc" ] ; then
                PLATFORM_ARCHITECTURE='power'
            fi
            ;;
        debian | ubuntu )
            PLATFORM_ARCHITECTURE="$(uname -m)"
            if [ "${PLATFORM_ARCHITECTURE}" = "ppc64le" ] ; then
                # Debian/Ubuntu name their package arch for Power8 as 'ppc64el'
                PLATFORM_ARCHITECTURE='ppc64el'
            fi
            ;;
        *)
            PLATFORM_ARCHITECTURE="$(uname -m)"
            ;;
    esac

    case "${PLATFORM_ARCHITECTURE}" in
        x86_64)
            case "${PLATFORM_NAME}" in
                ubuntu | debian )
                    PLATFORM_ARCHITECTURE=amd64
                    ;;
            esac
            ;;
        i686)
            PLATFORM_ARCHITECTURE=i386
            ;;
        ppc)
            PLATFORM_ARCHITECTURE=powerpc
            ;;
    esac
fi

# Tag
if [ -z "${PLATFORM_TAG:-""}" ]; then
    case "${PLATFORM_NAME}" in
        # Enterprise linux (centos & rhel) share the same packaging
        # Amazon linux is similar enough for our packages
        rhel | centos | amazon )
            PLATFORM_TAG="el-${PLATFORM_RELEASE}-${PLATFORM_ARCHITECTURE}"
            ;;
        *)
            PLATFORM_TAG="${PLATFORM_NAME}-${PLATFORM_RELEASE}-${PLATFORM_ARCHITECTURE}"
            ;;
    esac
fi

# This is the end of the code copied from the upstream installer.
##############################################################################

# vim: ft=sh



if ! bulk_pluginsync "https://ip-10-8-0-168.ap-southeast-2.compute.internal:8140/packages/bulk_pluginsync.tar.gz"; then
  echo "Plugin bulk download failed. Installation will proceed without it"
fi

run_agent_install_from_url "https://ip-10-8-0-168.ap-southeast-2.compute.internal:8140/packages/2021.7.6/${PLATFORM_TAG}.bash" "$@"

# ...and we should be good.
exit 0

# vim: ft=sh

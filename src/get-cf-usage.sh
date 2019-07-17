#!/usr/bin/env bash

function get-cf-usage() {
  local plugin_path=${PLUGIN_PATH:-bcr-plugin-linux}
  local config_path=${CONFIG_PATH:-config.yml}

  if [[ -n "${CF_RELATIVE_HOME:-}" ]]; then
    export CF_HOME=$(cd "$CF_RELATIVE_HOME" && pwd)
  fi

  local monthly_option=''
  if [[ ${MONTHLY:-false} == true ]]; then
    monthly_option=--monthly
  fi

  function yml_to_json() {
    ruby -ryaml -rjson -e "i = YAML::load(STDIN.read); puts i.to_json"
  }

  function _get-cf-usage() {
    local name=$1
    local endpoint=$2
    local skip_ssl_validation=$3
    local username="$4"
    local password="$5"

    local ssl_options=''
    if [[ $skip_ssl_validation == true ]]; then
      ssl_options=--skip-ssl-validation
    fi

    echo "Setting cf api $endpoint"
    cf api $endpoint $ssl_options

    echo "Logging in as $username"
    cf auth "$username" "$password"

    echo "Installing bcr-plugin: plugin/$plugin_path"
    cf install-plugin -f plugin/$plugin_path

    echo "Grabbing report and placing in report/${name}.txt"
    cf bcr $monthly_option --ai --si > report/${name}.txt
  }

  if [[ -f config/$config_path ]]; then
    for row in $(cat config/$config_path | yml_to_json | jq -rc '.[] | @base64' ); do
      function _jq() {
        echo "${row}" | base64 --decode | jq -r "$1"
      }

      _get-cf-usage $(_jq .name) $(_jq .endpoint) $(_jq '.["skip-ssl-validation"] // false') "$(_jq .username)" "$(_jq .password)"
    done
  else
    _get-cf-usage $REPORT_NAME $CF_ENDPOINT ${SKIP_SSL_VALIDATION:-false} "$CF_USERNAME" "$CF_PASSWORD"
  fi
}

if [[ ${BASH_SOURCE[0]} != $0 ]]; then
  export -f get-cf-usage
else
  set -euo pipefail

  get-cf-usage "${@:-}"
  exit $?
fi

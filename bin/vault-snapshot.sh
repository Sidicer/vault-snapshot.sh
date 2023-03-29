#!/usr/bin/env bash
#              _ _                           _       _         _   
#  _ _ ___ _ _| | |_ ___ ___ ___ ___ ___ ___| |_ ___| |_   ___| |_ 
# | | | .'| | | |  _|___|_ -|   | .'| . |_ -|   | . |  _|_|_ -|   |
#  \_/|__,|___|_|_|     |___|_|_|__,|  _|___|_|_|___|_| |_|___|_|_|
#                                   |_|                            
#
# Copyright (c) 2023 Deividas Gedgaudas • sidicer.lt

set -o nounset
set -o errtrace
set -o pipefail
IFS=$'\n\t'

_ME="$(basename "${0}")"

_SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export _SCRIPT_DIR=${_SCRIPT_DIR%/*}

_CONFIG_FILE=$_SCRIPT_DIR/config/vault-snapshot.cfg
_LOG_FILE=$_SCRIPT_DIR/logs/vault-snapshot.log
_CURRENT_TIME=`date +"%Y-%m-%dH%T"`

# Verbose Output Function + Logging
__VERBOSE=3
declare -A LOG_LEVELS
# https://en.wikipedia.org/wiki/Syslog#Severity_level
LOG_LEVELS=([0]="emerg" [1]="alert" [2]="crit" [3]="err" [4]="warning" [5]="notice" [6]="info" [7]="debug")

# Create logs dir
if [ ! -d "$_SCRIPT_DIR/logs" ]; then
  mkdir -p $_SCRIPT_DIR/logs
fi

function .log () {
  local LEVEL=${1}
  shift
  if [ ${__VERBOSE} -ge ${LEVEL} ]; then
    echo "[${LOG_LEVELS[$LEVEL]}]" "$@"
  fi
  echo "$_CURRENT_TIME" "[${LOG_LEVELS[$LEVEL]}]" "$@" >> "$_LOG_FILE"
}

_print_help() {
  cat <<HEREDOC
             _ _                           _       _         _   
 _ _ ___ _ _| | |_ ___ ___ ___ ___ ___ ___| |_ ___| |_   ___| |_ 
| | | .'| | | |  _|___|_ -|   | .'| . |_ -|   | . |  _|_|_ -|   |
 \_/|__,|___|_|_|     |___|_|_|__,|  _|___|_|_|___|_| |_|___|_|_|
                                  |_|                            

Tool used to easily download self-hosted HashiCorp Vault snapshot
  which can be automated with a simple cronjob

Requirements: curl, jq

Vault cluster should be unsealed and on standby.

Configuration for ${_ME} is set with:
  ${_CONFIG_FILE}

You must have a token generated with storage/raft READ permissions.
  The token must be placed in /config/vault_token file.
  (Location can be modified in /config/vault-snapshot.cfg)

Usage:
  ${_ME} [<arguments>]
  ${_ME} -h | Help - Show this screen.
  ${_ME} -v | Verbose - Show [info] level output (Default is error only)
  ${_ME} -c | Check - Only check which Vault node is the master
  ${_ME} -g | Get - Only get vault snapshot without checking for master node.
                         NOT RECOMMENDED!
Examples:
  ${_ME}       | Tool fully ran, silent output unless error.
  ${_ME} -vc   | Verbose output while only checking for master node.
  ${_ME} -c    | Only master node checked, silent output unless error
  ${_ME} -vg   | Verbose output while only getting Vault snapshot.
                            NOT RECOMMENDED!

HEREDOC
}

_loadConfigFile() {
  # Read configuration file and set borg repo path and backup file path
  if [ ! -f "$_CONFIG_FILE" ]; then
    .log 3 "$_CONFIG_FILE does not exist. Exiting..."
    exit 1
  fi

  source $_CONFIG_FILE
  .log 6 "Configuration successful."
  .log 6 "_CURRENT_MASTER_FILE=$_CURRENT_MASTER_FILE"
  .log 6 "_VAULT_TOKEN_FILE=$_VAULT_TOKEN_FILE"
  .log 6 "_VAULT_SNAPSHOT_PATH=$_VAULT_SNAPSHOT_PATH"
  .log 6 "_VAULT_URL=$_VAULT_URL"
}

_healthcheck() {
  _VAULT_HEALTHCHECK=`curl -s -o /dev/null -I -w "%{http_code}" "$_VAULT_URL/v1/sys/health"` 
  if [[ $_VAULT_HEALTHCHECK == "429" || $_VAULT_HEALTHCHECK == "200" ]]; then
    .log 6 "Healthcheck: Status OK"
  else
    .log 3 "Healthcheck: Status Unknown. Exiting..."
    exit 1
  fi
}

_findVaultMaster(){
  if [ `tail -1 $_LOG_FILE | grep err` ]; then
    .log 3 "Previous function ended with an error, please see $_LOG_FILE. Exiting..."
    exit 1
  else
    _VAULT_MASTER=`curl --silent $_VAULT_URL/v1/sys/leader | jq '.leader_address' | cut -d ':' -f2 | sed 's|//||'`
    echo $_VAULT_MASTER > $_CURRENT_MASTER_FILE
    .log 6 "_VAULT_MASTER=$_VAULT_MASTER"
  fi
}

_setVaultToken(){
  if [[ ! -f "$_VAULT_TOKEN_FILE" ]]; then
    .log 3 "Vault token missing. Exiting..."
    exit 1
  else
    export _VAULT_TOKEN="$(cat $_VAULT_TOKEN_FILE)"
    .log 6 "Vault token successfully set"
  fi
}

_getVaultSnapshot(){
  if [[ -z ${_VAULT_TOKEN} ]]; then
    .log 3 "Vault token not set. Exiting..."
    exit 1
  else
    .log 6 "Vault token found, attempting to get Vault Snapshot"
    if [[ ! -d "$_VAULT_SNAPSHOT_PATH" ]]; then
      mkdir $_VAULT_SNAPSHOT_PATH
    fi
    curl --silent --header "X-Vault-Token: $_VAULT_TOKEN" --request GET https://$(cat $_CURRENT_MASTER_FILE):8200/v1/sys/storage/raft/snapshot -o $_VAULT_SNAPSHOT_PATH/vault.snapshot
    if [ $? -eq 0 ]; then
      .log 6 "Vault snapshot succesfully downloaded to $_VAULT_SNAPSHOT_PATH/vault.snapshot"
    else
      .log 3 "Failed to download vault snapshot. Exiting..."
    fi
  fi
}

_options(){
  _OPT_VERBOSE="${_OPT_VERBOSE:-false}"
  _OPT_HELP="${_OPT_HELP:-false}"
  _OPT_CHECK="${_OPT_CHECK:-false}"
  _OPT_GET="${_OPT_GET:-false}"

  while getopts ":hvcg" opt; do
    case $opt in
      v) _OPT_VERBOSE=true;;
      h) _OPT_HELP=true;;
      c) _OPT_CHECK=true;;
      g) _OPT_GET=true;;
      ?) echo "[err] Unknown argument provided, see ${_ME} -h"; exit 1;;
    esac
  done
  shift $((OPTIND-1))
}

_main(){
  _options "$@"
  if [[ $_OPT_VERBOSE == true ]]; then __VERBOSE=6; fi
  if [[ $_OPT_HELP == true ]]; then _print_help; exit 0; fi
  if [[ $_OPT_CHECK == true ]]; then
    _loadConfigFile
    _healthcheck
    _findVaultMaster
    exit 0 
  fi
  if [[ $_OPT_GET == true ]]; then
    _loadConfigFile
    _setVaultToken
    _getVaultSnapshot
    exit 0
  else
    _loadConfigFile
    _healthcheck
    _findVaultMaster
    _setVaultToken
    _getVaultSnapshot
  fi
}

_main "$@"

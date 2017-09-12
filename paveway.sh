#!/bin/bash

# Print an error message to stderr and exit with non-zero code
fail() {
  echo "$@" >&2
  exit 1
}

# Print usage information for this script
usage() {
   fail "Usage: $0 [ssh-args] user@hostname"
}

# Remove any previously recorded host key for this host, and save the current one to the known_hosts file
clean_host_keys() {
  ssh-keygen -R "$1"
  ssh-keyscan -H "$1" >> ~/.ssh/known_hosts
}

# Open and parse the configuration file
read_config() {
  CONFIG_FILE="${HOME}/.pavewayrc"
  [[ ! -s "$CONFIG_FILE" ]] && fail "Configuration file $CONFIG_FILE does not exist or is empty."
  # The shellcheck linter does not like sourcing files from paths it can't check. SC1090
  # shellcheck source=/dev/null
  source $CONFIG_FILE
  [[ -z "$PAVEWAY_PASSWORDS" ]] && fail "Configuration file $CONFIG_FILE does not set the mandatory PAVEWAY_PASSWORDS variable."
}

# Try logging in to the remote host with each of the preconfigured passwords and copy the default ssh key
copy_key() {
  for p in "${PAVEWAY_PASSWORDS[@]}"; do
    sshpass -p "$p" ssh-copy-id "$1"  -o StrictHostKeyChecking=no && return
  done
  # If this code path is reached, none of the preconfigured passwords worked.
  fail "Connect failed, can't continue"
}

[[ $# == 0 ]] && usage
REMOTEHOST="$1"
read_config
clean_host_keys "$REMOTEHOST"
copy_key "$REMOTEHOST"
ssh "$REMOTEHOST"

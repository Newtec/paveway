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
  ssh-keygen -R "$REMOTEHOST"
  ssh-keyscan -H "$REMOTEHOST" >> ~/.ssh/known_hosts
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

# Try logging in to the remote host with each of the preconfigured passwords and transfer the default ssh key
transfer_key() {
  for p in "${PAVEWAY_PASSWORDS[@]}"; do
    sshpass -p "$p" ssh-copy-id -f "$REMOTEHOST"  -o StrictHostKeyChecking=no && return
  done
  # If this code path is reached, none of the preconfigured passwords worked.
  fail "Connect failed, can't continue"
}

# Transfer files to the remote host
transfer_files() {
  # Check if any files need to be transfered at all
  [[ -z "$PAVEWAY_XFER_FILES" ]] && return
  for f in "${PAVEWAY_XFER_FILES[@]}"; do
      # Check if the specified file exists in $PATH using which
      full_f_path=$(which "$f" 2>/dev/null)
      # Verify the result is an actual path, and not an alias
      echo "$full_f_path" | grep -qP '^/'
      [[ $? -eq 0 ]] || fail "Can't find file $f in \$PATH, so it can't be transferred."
      rsync -qav "$full_f_path" "${REMOTEHOST}:/bin/"
  done
}

# Log in with SSH, unless $PAVEWAY_SSH disallows it.
start_ssh() {
  # case insensitive matching
  shopt -s nocasematch
  if [[ $PAVEWAY_SSH =~ "false" ]] || [[ $PAVEWAY_SSH == "0" ]] ; then
    return
  fi
  shopt -u nocasematch
  ssh "$REMOTEHOST"
}

[[ $# == 0 ]] && usage
REMOTEHOST="$1"
read_config
clean_host_keys
transfer_key
transfer_files
start_ssh

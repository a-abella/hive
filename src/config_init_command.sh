# shellcheck disable=SC2168
# echo "# this file is located in 'src/config_init_command.sh'"
# echo "# code for 'hive config init' goes here"
# echo "# you can edit it freely and regenerate (it will not be overwritten)"
#inspect_args

config_eval() {
  declare -A user_input
  dbg_echo "$(printarr CURRENT_CLUSTER)"
  if [[ ! "${CURRENT_CLUSTER[*]}" || "${args[--reset-clusters]}" ]]; then
    dbg_echo "running config_init_cluster"
    print_banner "tagline"
    echo
    config_init_cluster
    local RAN_INIT_CLUSTER=1
  fi
  echo; config_init_ssh
  echo; config_init_prompt
}

initialize_cluster_context() {
  local j="{\"$1\": {\"desc\": \"$2\", \"managers\": [\"$3\"]}}"
  config_set cluster_map "$j"
  config_set cluster_current "$1"
  load_hive_cluster
  dbg_echo "INITIALIZED AND LOADED CLUSTER DATA"
  dbg_echo "$(printarr CURRENT_CLUSTER)"
}

config_init_cluster() {
  fmt_echo "Define your first cluster!"
  echo
  fmt_echo "Set an identifying cluster name"
  read -p "  name: " user_input["cluster_name"]
  echo
  fmt_echo "Clusters can have optional descriptions"
  read -p "  description: " user_input["cluster_desc"]
  
  echo
  fmt_echo "Hive needs to know a Swarm manager hostname or address belonging to this cluster to interact with services and nodes; more managers can be added or autodiscovered later"
  echo
  fmt_echo "Set a manager hostname or address"
  read -p "  manager: " user_input["cluster_manager"]
  ## CLUSTER TIME BAYBEEEE
  initialize_cluster_context "${user_input["cluster_name"]}" "${user_input["cluster_desc"]}" "${user_input["cluster_manager"]}"
  echo
  :
}

config_init_ssh() {
  fmt_echo "Tune SSH settings!"
  echo
  fmt_echo "Hive communicates with Docker nodes using ssh with private-key authentication; the provided ssh user must be present on all docker systems in the Swarm cluster, and the user must have access to each node's local docker socket"
  echo
  fmt_echo "SSH credential settings"
  read -p "  ssh user [$USER]: " user_input["ssh_user"]
  if [[ ! "${user_input["ssh_user"]}" ]]; then
    user_input["ssh_user"]="$(config_get ssh_credential_user)"
  else
    config_set ssh_credential_user "${user_input["ssh_user"]}"
  fi
  
  read -p "  ssh private key (default ssh client key search behavior if left blank): " user_input["ssh_identity"]
  if [[ ! "${user_input["ssh_identity"]}" ]]; then
    user_input["ssh_identity"]="$(config_get ssh_credential_identity_file)"
  else
    [[ -n "$(validate_file_exists "${user_input["ssh_identity"]}")" ]] && echo "ERROR: ssh private key path not found" && false
    config_set ssh_credential_identity_file "${user_input["ssh_identity"]}"
  fi
  
  echo
  fmt_echo "Hive can handle some ssh quality-of-life configurations like managing host_keys and autoconfiguring multiplexing; reasonable defaults are provided for all configuration options"
  echo
  fmt_echo "SSH config settings"
  read -p "  ssh config path [$HOME/.ssh/config]: " user_input["ssh_config"]
  [[ ! "${user_input["ssh_config"]}" ]] && user_input["ssh_config"]="$(config_get ssh_config_file)"
  
  if [[ "$(config_get ssh_multiplex_enabled | tr 'A-Z' 'a-z')" =~ ^(yes|true|y)$ ]]; then
    local def_multip="Y/n"
  else
    local def_multip="y/N"
  fi
  read -p "  enable ssh multiplexing? [$def_multip]: " user_input["ssh_multiplex_enable"]
  [[ ! "${user_input["ssh_multiplex_enable"]}" ]] && user_input["ssh_multiplex_enable"]="$(config_get ssh_multiplex_enabled)"
  
  echo
  fmt_echo "SSH multiplexing behavior can be fine tuned; for more information see \`man ssh_config\`"
  fmt_echo "Even if you disabled multiplexing in the last step, these settings will be saved for later"
  echo
  fmt_echo "SSH multiplex settings"
  read -p "  ssh multiplex ControlPath [$(config_get ssh_multiplex_controlpath)]: " user_input["ssh_controlpath"]
  read -p "  ssh multiplex ControlPersist [$(config_get ssh_multiplex_controlpersist)]: " user_input["ssh_controlpersist"]
  read -p "  ssh multiplex ServerAliveInterval [$(config_get ssh_multiplex_serveraliveinterval)]: " user_input["ssh_aliveinterval"]
  echo
  fmt_echo "SSH host_keys can be automatically pruned and imported from discovered cluster nodes, useful if nodes are recreated during system upgrades or if there are too many nodes to manually accept host_keys for"
  echo
  fmt_echo "SSH host_keys settings"
  read -p "  ssh custom KeyFile path [$(config_get ssh_keyfile_path)]: " user_input["ssh_keyfile"]
  default_hsk="$(config_get ssh_keyfile_hashknownhosts)"
  if [[ "$default_hsk" =~ ^[yY][eE][sS]$ ]]; then
    default_hsk="Y/n"
  elif [[ "$default_hsk" =~ ^[nN][oO]$ ]]; then
    default_hsk="y/N"
  else
    fmt_echo "ERROR: invalid config \"ssh_keyfile_hashknownhosts = $default_hsk\" in $CONFIG_FILE"
  fi
  read -p "  ssh KeyFile HashKnownHosts [$default_hsk]: " user_input["ssh_hashknownhosts"]
  echo
  fmt_echo "The following SSH configurations will be applied based on your selections:"
  echo
  local hive_ssh_config_file="${user_input["ssh_config"]}_hive"
  echo "# The file $hive_ssh_config_file will be created"
  echo "# with the following content:"
  echo

  local ssh_config_hive_printf_b64="SG9zdCAlcwogICMgdGhlIHVzZXIgdXNlZCB0byBzc2ggdG8gc3dhcm0gbm9kZXMKICBVc2VyICVzCiAgIyBwcml2YXRlIGtleSBmb3IgdGhlIGdpdmVuIHVzZXIKICBJZGVudGl0eUZpbGUgJXMKICAjIGVuYWJsZSBtdWx0aXBsZXhpbmcgKHllc3xhdXRvID0gZW5hYmxlZCwgbm8gPSBkaXNhYmxlZCkKICBDb250cm9sTWFzdGVyICVzCiAgIyBsb2NhdGlvbiBhbmQgdGVtcGxhdGUgZm9yIG11bHRpcGxleGluZyBzc2ggc29ja2V0cwogIENvbnRyb2xQYXRoICVzCiAgIyBkdXJhdGlvbiB0byByZXRhaW4gb3BlbiBzb2NrZXRzCiAgQ29udHJvbFBlcnNpc3QgJXMKICAjIGludGVydmFsIHRvIHNlbmQga2VlcGFsaXZlIHNpZ25hbHMKICBTZXJ2ZXJBbGl2ZUludGVydmFsICVzCiAgIyB3aGVyZSB0byBzdG9yZSBoaXZlLW1hbmFnZWQgaG9zdGtleXMKICBVc2VLbm93bkhvc3RzRmlsZSAlcwogICMgY29udHJvbCBob3N0a2V5IGhhc2hpbmcKICBIYXNoS25vd25Ib3N0cyAlcwoK"
  ## ssh_config_give_printf_b64 resolves to a printf string that will ultimately resembe the following:
  ## have to use base64+printf because bashly's handling of heredocs is broken
  ##
  ## Host ${user_input["cluster_manager"]}
  ##   # the user used to ssh to swarm nodes
  ##   User ${user_input["ssh_user"]}
  ##   # private key for the given user
  ##   IdentityFile ${user_input["ssh_identity"]}
  ##   # enable multiplexing (yes|auto = enabled, no = disabled)
  ##   ControlMaster $([[ "${user_input["ssh_multiplex_enable"]}" =~ ^[yY][eE]?[sS]?$ ]] && echo Auto || echo no)
  ##   # location and template for multiplexing ssh sockets
  ##   ControlPath ${user_input["ssh_multiplex_controlpath"]}
  ##   # duration to retain open sockets
  ##   ControlPersist ${user_input["ssh_multiplex_controlpersist"]}
  ##   # interval to send keepalive signals
  ##   ServerAliveInterval ${user_input["ssh_multiplex_aliveinterval"]}
  ##   # where to store hive-managed hostkeys
  ##   UseKnownHostsFile ${user_input["ssh_keyfile"]}
  ##   # control hostkey hashing
  ##   HashKnownHosts ${user_input["ssh_hashknownhosts"]}
  
  # shellcheck disable=SC2059
  printf "$(base64 -d <<< "$ssh_config_hive_printf_b64")" "${user_input["cluster_manager"]}" "${user_input["ssh_user"]}" "${user_input["ssh_identity"]}" "$([[ "${user_input["ssh_multiplex_enable"]}" =~ ^[yY][eE]?[sS]?$ ]] && echo Auto || echo no)" "${user_input["ssh_multiplex_controlpath"]}" "${user_input["ssh_multiplex_controlpersist"]}" "${user_input["ssh_multiplex_aliveinterval"]}" "${user_input["ssh_keyfile"]}" "${user_input["ssh_hashknownhosts"]}" | tee "$hive_ssh_config_file"
  echo
  echo
  local hive_include="Include \"$hive_ssh_config\""
  local base_config_content
  base_config_content="$(grep -v "$hive_include" "$(config_get ssh_config_file)")"
  if [[ "$(config_get ssh_config_manage | tr '[:upper:]' '[:lower:]')" =~ ^(y|yes|true|1)$ ]]; then
    echo "# Hive will write the following"
    echo "# to ${user_input["ssh_config"]}:"
    echo
    local ssh_config_prio
    ssh_config_prio="$(config_get ssh_config_priority | tr '[:upper:]' '[:lower:]')"
    local l
    local ssh_config_content
    if [[ "$ssh_config_prio" = "before" ]]; then
      l="$(head -n1 <<< "$base_config_content")"
      [[ "${l// }" ]] && local blank='\n\n' || local blank='\n'
      # shellcheck disable=SC2001
      ssh_config_content="$(sed "1 s/^/$hive_include$blank/" <<< "$base_config_content")"
    elif [[  "$ssh_config_prio" = "after" ]]; then
      l="$(tail -n1 <<< "$base_config_content")"
      [[ "${l// }" ]] && local blank=$'\n\n' || local blank=$'\n'
      ssh_config_content="$base_config_content$blank$hive_include"
    else
      fmt_echo "ERROR: invalid settings value for ssh_config_priority"
      false
    fi
    tee "$(config_get ssh_config_file)" <<< "$ssh_config_content"
  else
    echo -e "$base_config_content" > "$(config_get ssh_config_file)"
  fi
  #tee "${user_input["ssh_config"]}" <<< "$import_ssh_config_hive"
  echo
  
  
}

config_init_prompt() {
  fmt_echo "Define your prompt injection!"
  echo
  fmt_echo "Hive can inject a template into your PS1 prompt to show which cluster you are actively managing. This prompt is customizable using a templating system. See \`hive config prompt update --help\` for template syntax information"
  :
}

#clear
config_eval


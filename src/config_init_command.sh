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
  fmt_echo "Hive can handle some ssh quality-of-life configurations like managing Swarm node ssh access credentials, controlling host_keys, and autoconfiguring multiplexing; reasonable defaults are provided for all configuration options"
  echo
  local _ssh_conf_manage
  _ssh_conf_manage="$(config_get ssh_config_manage)"
  if [[ "$_ssh_conf_manage" =~ ^(y|yes|true|1)$ ]]; then
    local def_ssh_mg="Y/n"
    local _ssh_mg_enable=1
    config_set ssh_config_manage "true"
  elif [[ "$_ssh_conf_manage" =~ ^(n|no|false|0|[[:space:]]*)$ ]]; then
    local def_ssh_mg="y/N"
    local _ssh_mg_enable=0
    config_set ssh_config_manage "false"
  fi
  read -p "  enable ssh config management? [$def_ssh_mg]: " user_input["ssh_config_manage"]
  if [[ ! "${user_input["ssh_config_manage"]// }" ]]; then
    user_input["ssh_config_manage"]="$(config_get ssh_config_manage)"
  else
    config_set ssh_config_manage "${user_input["ssh_config_manage"]}"
  fi
  echo
  if [[ "${user_input[ssh_config_manage],,}" =~ ^(y|yes|true|1)$ ]]; then
    fmt_echo "Tune SSH settings!"
    echo
    fmt_echo "Hive communicates with Docker nodes using ssh with private-key authentication; the provided ssh user must be present on all docker systems in the Swarm cluster, and the user must have access to each node's local docker socket"
    echo
    fmt_echo "SSH credential settings"
    read -p "  ssh user [$USER]: " user_input["ssh_user"]
    if [[ ! "${user_input["ssh_user"]// }" ]]; then
      user_input["ssh_user"]="$(config_get ssh_credential_user)"
    else
      config_set ssh_credential_user "${user_input["ssh_user"]}"
    fi
    
    read -p "  ssh private key (default ssh client key search behavior if left blank): " user_input["ssh_identity"]
    if [[ ! "${user_input["ssh_identity"]// }" ]]; then
      user_input["ssh_identity"]="$(config_get ssh_credential_identity_file)"
    else
      [[ -n "$(validate_file_exists "${user_input["ssh_identity"]}")" ]] && echo "ERROR: ssh private key path not found" && false
      config_set ssh_credential_identity_file "${user_input["ssh_identity"]}"
    fi
    fmt_echo "SSH config settings"
    local _ssh_conf_path
    _ssh_conf_path="$(config_get ssh_config_file)"
    [[ ! "${_ssh_conf_path// }" ]] && _ssh_conf_path="$HOME/.ssh/config"
    read -p "  ssh config path [$_ssh_conf_path]: " user_input["ssh_config"]
    if [[ ! "${user_input["ssh_config"]// }" ]]; then
      user_input["ssh_config"]="$_ssh_conf_path"
    else
      config_set ssh_config_file "${user_input["ssh_config"]}"
    fi
    
    local _ssh_multiplex_enabled
    _ssh_multiplex_enabled="$(config_get ssh_multiplex_enabled | tr '[:upper:]' '[:lower:]')"
    if [[ "$_ssh_multiplex_enabled" =~ ^(y|yes|true|1)$ ]]; then
      local def_multip="Y/n"
      config_set ssh_multiplex_enabled "true"
    elif [[ "$_ssh_multiplex_enabled" =~ ^(n|no|false|0|[[:space:]]*)$ ]]; then
      local def_multip="y/N"
      config_set ssh_multiplex_enabled "false"
    fi
    read -p "  enable ssh multiplexing? [$def_multip]: " user_input["ssh_multiplex_enable"]
    if [[ ! "${user_input["ssh_multiplex_enable"]// }" ]]; then
      user_input["ssh_multiplex_enable"]="$(config_get ssh_multiplex_enabled)"
    else
      config_set ssh_multiplex_enabled "${user_input["ssh_multiplex_enable"]}"
    fi
    echo
    if [[ "${user_input["ssh_multiplex_enable"]// }" =~ ^(n|no|false|0|[[:space:]]*)$ ]]; then
      fmt_echo "Skipping SSH multiplex configuration. You can enable and configure it later with 'hive config ssh multiplex enable' and 'hive config ssh multiplex update'"
    else
      fmt_echo "SSH multiplexing behavior can be fine tuned; for more information see \`man ssh_config\`"
      fmt_echo "Even if you disabled multiplexing in the last step, these settings will be saved for later"
      echo
      fmt_echo "SSH multiplex settings"
      # TODO: handle these and insert
      read -p "  ssh multiplex ControlPath [$(config_get ssh_multiplex_controlpath)]: " user_input["ssh_controlpath"]
      read -p "  ssh multiplex ControlPersist [$(config_get ssh_multiplex_controlpersist)]: " user_input["ssh_controlpersist"]
      read -p "  ssh multiplex ServerAliveInterval [$(config_get ssh_multiplex_serveraliveinterval)]: " user_input["ssh_aliveinterval"]
    fi
    echo
    fmt_echo "SSH host_keys can be automatically imported and pruned from discovered cluster nodes, useful if nodes are recreated during system upgrades or if there are too many nodes to manually accept hostkeys for"
    echo
    fmt_echo "Hive will maintain a separate SSH host_keys file from the user default to facilitate cluster host-key management"
    echo
    fmt_echo "SSH host_keys settings"
    local _ssh_keyfile
    _ssh_keyfile="$(config_get ssh_keyfile_path)"
    if [[ ! "${_ssh_keyfile// }" ]]; then
      _ssh_keyfile="$HOME/.ssh/_hive_known_hosts"
      config_set ssh_keyfile_path "$_ssh_keyfile"
    fi
    read -p "  ssh custom KeyFile path [$_ssh_keyfile]: " user_input["ssh_keyfile"]
    if [[ "${user_input["ssh_keyfile"]// }" ]]; then 
      config_set ssh_keyfile_path "${user_input["ssh_keyfile"]}"
    fi
    
    local _ssh_hsk_enabled
    _ssh_hsk_enabled="$(config_get ssh_keyfile_hashknownhosts | tr '[:upper:]' '[:lower:]')"
    if [[ "$_ssh_hsk_enabled" =~ ^(y|yes|true|1)$ ]]; then
      local def_hsk="Y/n"
      local _hsk_enable=1
      config_set ssh_keyfile_hashknownhosts "true"
    elif [[ "$_ssh_hsk_enabled" =~ ^(n|no|false|0|[[:space:]]*)$ ]]; then
      local def_hsk="y/N"
      local _hsk_enable=0
      config_set ssh_keyfile_hashknownhosts "false"
    else
      fmt_echo "ERROR: invalid config \"ssh_keyfile_hashknownhosts = $_ssh_hsk_enabled\" in $CONFIG_FILE"
    fi
    read -p "  ssh KeyFile HashKnownHosts [$def_hsk]: " user_input["ssh_hashknownhosts"]
    if [[ ! "${user_input["ssh_hashknownhosts"]// }" ]]; then
      user_input["ssh_hashknownhosts"]="$(config_get ssh_keyfile_hashknownhosts)"
    else
      config_set ssh_keyfile_hashknownhosts "${user_input["ssh_hashknownhosts"]}"
    fi
    
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
    printf "$(base64 -d <<< "$ssh_config_hive_printf_b64")" "${user_input["cluster_manager"]}" "${user_input["ssh_user"]}" "${user_input["ssh_identity"]}" "$([[ "${user_input["ssh_multiplex_enable"],,}" =~ ^(y|yes|true|1)$ ]] && echo Auto || echo no)" "${user_input["ssh_multiplex_controlpath"]}" "${user_input["ssh_multiplex_controlpersist"]}" "${user_input["ssh_multiplex_aliveinterval"]}" "${user_input["ssh_keyfile"]}" "${user_input["ssh_hashknownhosts"]}" \
      | cat
      #| tee "$hive_ssh_config_file"  #FINDME
    
    echo
    echo
    local hive_include="Include \"$hive_ssh_config\""
    local base_config_content
    base_config_content="$(grep -v "$hive_include" "$(config_get ssh_config_file)")"
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
    # FINDME
    #tee "$(config_get ssh_config_file)" <<< "$ssh_config_content"
    cat <<< "$ssh_config_content"
  else
    fmt_echo "By disabling ssh config management you will be responsible for defining all required ssh_config entries for ssh access from this machine to the Hive-managed Swarm nodes"
  fi
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


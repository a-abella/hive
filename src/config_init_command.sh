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
  sec_head "Initial setup is complete!"
  echo
  fmt_echo "Try a command like 'hive docker ps' to execute against your configured cluster!"
}

sec_head() {
  echo "##"
  echo "## $*"
  echo "##"
}

initialize_cluster_context() {
  local j="{\"$1\": {\"description\": \"$2\", \"managers\": [\"$3\"]}}"
  config_set cluster_map "$j"
  config_set cluster_current "$1"
  load_hive_cluster
  dbg_echo "INITIALIZED AND LOADED CLUSTER DATA"
  dbg_echo "$(printarr CURRENT_CLUSTER)"
}

config_init_cluster() {
  sec_head "Define your first cluster!"
  echo
  fmt_echo "Hive stores cluster data in you local config file. This will guide you through setting up your first cluster."
  echo
  fmt_echo "Set an identifying cluster name"
  read -p "  name: " user_input["cluster_name"]
  echo
  fmt_echo "Clusters can have optional descriptions"
  read -p "  description: " user_input["cluster_desc"]
  
  echo
  fmt_echo "Hive needs to know a Swarm manager hostname or address belonging to this cluster to interact with services and nodes; more managers can be added or autodiscovered later."
  echo
  fmt_echo "Set a manager hostname or address"
  local _cluster_manager_valid=0
  while [[ $_cluster_manager_valid -eq 0 ]]; do
    read -p "  manager: " user_input["cluster_manager"]
    if [[ -n "$(validate_cluster_host "${user_input["cluster_manager"]}")" ]]; then
      echo "error: provided hostname is not a valid DNS hostname or IP address"
    else
      _cluster_manager_valid=1
    fi
  done
  ## CLUSTER TIME BAYBEEEE
  initialize_cluster_context "${user_input["cluster_name"]}" "${user_input["cluster_desc"]}" "${user_input["cluster_manager"]}"
  echo
  fmt_echo "Your first cluster \"${CURRENT_CLUSTER[name]}\" has been saved! More clusters can be added later with 'hive config cluster add'."
  echo
  fmt_echo "When you have multiple clusters, you can switch between them with"
  fmt_echo "'hive config cluster use [cluster_name]'."
  echo -e '\n==='
  :
}

config_init_ssh() {
  sec_head "Configure SSH settings!"
  echo
  fmt_echo "Hive can handle some SSH quality-of-life configurations like managing Swarm node SSH access credentials, controlling host_keys, and autoconfiguring multiplexing; reasonable defaults are provided for all configuration options."
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
  read -p "  enable SSH config management? [$def_ssh_mg]: " user_input["ssh_config_manage"]
  if [[ ! "${user_input["ssh_config_manage"]// }" ]]; then
    user_input["ssh_config_manage"]="$(config_get ssh_config_manage)"
  else
    config_set ssh_config_manage "${user_input["ssh_config_manage"]}"
  fi
  echo
  if [[ "${user_input[ssh_config_manage],,}" =~ ^(y|yes|true|1)$ ]]; then
    fmt_echo "Tune SSH settings!"
    echo
    fmt_echo "Hive communicates with Docker nodes using SSH with private-key authentication; the provided SSH user must be present on all docker systems in the Swarm cluster, and the user must have access to each node's local docker socket."
    echo
    fmt_echo "SSH credential settings"
    read -p "  SSH user [$USER]: " user_input["ssh_user"]
    if [[ ! "${user_input["ssh_user"]// }" ]]; then
      user_input["ssh_user"]="$(config_get ssh_credential_user)"
    else
      config_set ssh_credential_user "${user_input["ssh_user"]}"
    fi
    
    local _ssh_key_path="$(config_get ssh_credential_identity_file)"
    local _ssh_key_prefill
    if [[ "${_ssh_key_path// }" ]]; then
      _ssh_key_prefill="[$_ssh_key_path]"
    else
      _ssh_key_prefill="(must not be left blank)"
    fi
    local _ssh_key_read=0
    while [[ $_ssh_key_read -eq 0 ]]; do
      read -e -p "  SSH private key path $_ssh_key_prefill: " user_input["ssh_identity"]
      if [[ ! "${user_input["ssh_identity"]// }" ]]; then
        if [[ ! "${_ssh_key_path// }" ]]; then
          fmt_echo "error: SSH key path must not be blank"
        else
          user_input["ssh_identity"]="$(config_get ssh_credential_identity_file)"
          [[ -n "$(validate_file_exists "${user_input["ssh_identity"]}")" ]] && echo "ERROR: provided ssh private key path not found" && false
          _ssh_key_read=1
        fi
      else
        [[ -n "$(validate_file_exists "${user_input["ssh_identity"]}")" ]] && echo "ERROR: provided ssh private key path not found" && false
        config_set ssh_credential_identity_file "${user_input["ssh_identity"]}"
        _ssh_key_read=1
      fi
    done
    fmt_echo "SSH config settings"
    local _ssh_conf_path
    _ssh_conf_path="$(config_get ssh_config_file)"
    [[ ! "${_ssh_conf_path// }" ]] && _ssh_conf_path="$HOME/.ssh/config"
    read -e -p "  ssh config path [$_ssh_conf_path]: " user_input["ssh_config"]
    if [[ ! "${user_input["ssh_config"]// }" ]]; then
      user_input["ssh_config"]="$_ssh_conf_path"
      [[ -n "$(validate_file_exists "${user_input["ssh_config"]}")" ]] && echo "ERROR: ssh config file path not found" && false
    else
      [[ -n "$(validate_file_exists "${user_input["ssh_config"]}")" ]] && echo "ERROR: ssh config file path not found" && false
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
      fmt_echo "Skipping SSH multiplex configuration. You can enable and configure it later with 'hive config ssh multiplex enable' and 'hive config ssh multiplex update'."
    else
      fmt_echo "SSH multiplexing behavior can be fine tuned; for more information see 'man ssh_config'."
      fmt_echo "Even if you disabled multiplexing in the last step, these settings will be saved for later."
      echo
      fmt_echo "SSH multiplex settings"
      # TODO: handle these and insert
      read -p "  ssh multiplex ControlPath [$(config_get ssh_multiplex_controlpath)]: " user_input["ssh_multiplex_controlpath"]
      if [[ ! "${user_input["ssh_multiplex_controlpath"]// }" ]]; then
        user_input["ssh_multiplex_controlpath"]="$(config_get ssh_multiplex_controlpath)"
      else
        config_set ssh_multiplex_controlpath "${user_input["ssh_multiplex_controlpath"]}"
      fi
      read -p "  ssh multiplex ControlPersist [$(config_get ssh_multiplex_controlpersist)]: " user_input["ssh_multiplex_controlpersist"]
      if [[ ! "${user_input["ssh_multiplex_controlpersist"]// }" ]]; then
        user_input["ssh_multiplex_controlpersist"]="$(config_get ssh_multiplex_controlpersist)"
      else
        config_set ssh_multiplex_controlpersist "${user_input["ssh_multiplex_controlpersist"]}"
      fi
      read -p "  ssh multiplex ServerAliveInterval [$(config_get ssh_multiplex_serveraliveinterval)]: " user_input["ssh_multiplex_aliveinterval"]
      if [[ ! "${user_input["ssh_multiplex_aliveinterval"]// }" ]]; then
        user_input["ssh_multiplex_aliveinterval"]="$(config_get ssh_multiplex_serveraliveinterval)"
      else
        config_set ssh_multiplex_serveraliveinterval "${user_input["ssh_multiplex_aliveinterval"]}"
      fi
    fi
    echo
    fmt_echo "SSH host_keys can be automatically imported and pruned from discovered cluster nodes, useful if nodes are recreated during system upgrades or if there are too many nodes to manually accept hostkeys for."
    echo
    fmt_echo "Hive will maintain a separate SSH host_keys file from the user default to facilitate cluster host-key management."
    echo
    fmt_echo "SSH host_keys settings"
    local _ssh_keyfile
    _ssh_keyfile="$(config_get ssh_keyfile_path)"
    if [[ ! "${_ssh_keyfile// }" ]]; then
      _ssh_keyfile="$(dirname "${user_input["ssh_config"]}")/hive_known_hosts"
      config_set ssh_keyfile_path "$_ssh_keyfile"
    fi
    read -p "  ssh custom KeyFile path [$_ssh_keyfile]: " user_input["ssh_keyfile"]
    if [[ "${user_input["ssh_keyfile"]// }" ]]; then 
      [[ -n "$(validate_dir_exists "$(dirname "${user_input["ssh_keyfile"]}")")" ]] && echo "ERROR: ssh KeyFile parent dir path not found" && false
      config_set ssh_keyfile_path "${user_input["ssh_keyfile"]}"
    else
      user_input["ssh_keyfile"]="$(config_get ssh_keyfile_path)"
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
    local hive_ssh_config_file
    hive_ssh_config_file="$(dirname "${user_input["ssh_config"]}")/hive_ssh_config"
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
    local hive_include="Include ./hive_ssh_config"
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
    fmt_echo "By disabling SSH config management you will be responsible for maintaining SSH access configs to the Hive-managed Swarm nodes."
  fi
  echo -e '\n==='
}

config_init_prompt() {
  sec_head "Keep track of your active cluster!"
  echo
  fmt_echo "Hive provides helper commands to inject a current-cluster label into your PS1 prompt."
  echo
  fmt_echo "Hive cannot directly manage unexported shell variables like PS1. You can manually toggle prompt injection by passing command output to 'eval'."
  echo
  fmt_echo "To enable:"
  echo "  eval \"\$(hive config prompt enable)\""
  echo
  fmt_echo "To disable:"
  echo "  eval \"\$(hive config prompt disable)\""
  echo
  fmt_echo "If you'd rather manage PS1 yourself, you can print current cluster data with 'hive config cluster show'"
  echo
}

#clear
config_eval


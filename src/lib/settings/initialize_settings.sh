
initialize_settings() {
  config_init
  case "$1" in
    cluster )
      initialize_cluster_settings
    ;;
    prompt )
      initialize_prompt_settings
    ;;
    ssh )
      initialize_ssh_settings
    ;;
    all )
      initialize_ssh_settings
      initialize_prompt_settings
      initialize_cluster_settings
    ;;
    * )
      fmt_echo "BUG: unknown call '${FUNCNAME[0]} $*'"
      false
    ;;
  esac
    
}

write_conf_items() {
  local -n setting_map_nref=$1
  local -n desc_map_nref=$2
  local conf_item
  for conf_item in $(tr ' ' $'\n' <<< "${!setting_map_nref[@]}" | sort); do
    if ! config_has_key "$conf_item"; then
      dbg_echo "setting default value: $conf_item = ${setting_map_nref[$conf_item]}"
      if [[ ! "${args[--force]}" -eq 1 ]]; then
        echo "${desc_map_nref[$conf_item]}" >> "$CONFIG_FILE"
      fi
      config_set "$conf_item" "${setting_map_nref[$conf_item]}"
    fi
  done
}

initialize_ssh_settings() {
    # shellcheck disable=SC2034
    declare -A setting_map=(
      [ssh_config_manage]="false"
      [ssh_config_file]="$HOME/.ssh/config"
      [ssh_config_priority]="after"
      [ssh_credential_user]="$USER"
      [ssh_credential_identity_file]=""
      [ssh_keyfile_path]="$HOME/.ssh/_hive_known_hosts"
      [ssh_keyfile_hashknownhosts]="yes"
      [ssh_multiplex_enabled]="true"
      [ssh_multiplex_controlpath]="$HOME/.ssh/_hive_%r@%h.sock"
      [ssh_multiplex_controlpersist]="60m"
      [ssh_multiplex_serveraliveinterval]="300"
    )
    # shellcheck disable=SC2034
    declare -A -g ssh_desc_map=(
      [ssh_config_manage]="; Allow hive to manage ssh_config settings"
      [ssh_config_file]="; Path to the ssh_credential_user's ssh_config file, usually \$HOME/.ssh/config"
      [ssh_config_priority]="; Place hive-managed ssh_config either BEFORE or AFTER user-managed settings (before | after)\n;; ssh_config values are used on a first-match basis"
      [ssh_credential_user]="; The ssh username to be used in DOCKER_HOST ssh sessions"
      [ssh_credential_identity_file]="; Path to the private key file for the given ssh user,\n;; if left blank default ssh key search behavior is used"
      [ssh_keyfile_path]="; Path to the hive-managed known_hosts keyfile location"
      [ssh_keyfile_hashknownhosts]="; Sets ssh HashKnownHosts value"
      [ssh_multiplex_enabled]="; Inject ssh multiplexing to sshconfig location for DOCKER_HOSTs (true | false)\n;; Reference 'man ssh_config' for further information on ControlMaster configurations and options"
      [ssh_multiplex_sshconfig]="; Path to the ssh_config file for the given ssh user"
      [ssh_multiplex_controlpath]="; Path and filename template string for ssh ControlMaster ControlPath socket files"
      [ssh_multiplex_controlpersist]="; Duration to retain multiplexed ssh connection sockets"
      [ssh_multiplex_serveraliveinterval]="; Interval duration in seconds to send KeepAlive packets over the active ssh session"
    )
    
    write_conf_items setting_map ssh_desc_map
}

initialize_prompt_settings() {
    # shellcheck disable=SC2034
    declare -A setting_map=(
      [prompt_enabled]="true"
      [prompt_template]="'^({CLUSTER}) '"
    )
    # shellcheck disable=SC2034
    declare -A -g prompt_desc_map=(
      [prompt_enabled]="; Enable shell PS1 prompt template injection (true | false)"
      [prompt_template]="; PS1 prompt template string, refer to 'hive config prompt update --help'"
    )
    write_conf_items setting_map prompt_desc_map
}

initialize_cluster_settings() {
    # shellcheck disable=SC2034
    declare -A setting_map=(
      [cluster_current]=""
      [cluster_map]=""
    )
    # shellcheck disable=SC2034
    declare -A -g cluster_desc_map=(
      [cluster_current]="; The currently selected hive cluster"
      [cluster_map]="; Cluster metadata for hive management"
    )
    write_conf_items setting_map cluster_desc_map
}


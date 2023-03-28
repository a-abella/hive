
initialize_settings() {
  config_init
  case "$1" in
    context )
      initialize_context_settings "$2"
    ;;
    prompt )
      initialize_prompt_settings "$2"
    ;;
    ssh )
      initialize_ssh_settings "$2"
    ;;
    all )
      initialize_ssh_settings "$2"
      initialize_prompt_settings "$2"
      initialize_context_settings "$2"
    ;;
    * )
      fmt_echo "BUG: unknown call '${FUNCNAME[0]} $*'"
      false
    ;;
  esac
    
}

write_conf_items() {
  local -n setting_map_nref=$1
  local conf_item
  for conf_item in "${!setting_map_nref[@]}"; do
    if ! config_has_key "$conf_item" || [[ "${args[--force]}" ]]; then
      config_set  "$conf_item" "${setting_map_nref[$conf_item]}"
    fi
  done
}

initialize_ssh_settings() {
    declare -A setting_map=(
      [ssh_credential_user]="$USER"
      [ssh_multiplex_enabled]="true"
      [ssh_multiplex_sshconfig]="$HOME/.ssh/config"
      [ssh_multiplex_controlpath]="$HOME/.ssh/hive__%r@%h.sock"
      [ssh_multiplex_controlpersist]="60m"
      [ssh_multiplex_serveraliveinterval]="300"
    )
    write_conf_items setting_map
}

initialize_prompt_settings() {
    declare -A setting_map=(
      [prompt_enabled]="true"
      [prompt_template]="^({CLUSTER}|{CONTEXT}) "
    )
    write_conf_items setting_map
}

initialize_context_settings() {
    declare -A setting_map=(
      [context_current]=""
      [context_list]=""
    )
    write_conf_items setting_map
}


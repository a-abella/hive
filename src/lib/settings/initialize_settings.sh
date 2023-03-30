
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
  local conf_item
  for conf_item in "${!setting_map_nref[@]}"; do
    if ! config_has_key "$conf_item" || [[ "${args[--force]}" -eq 1 ]]; then
      dbg_echo "setting default value: $conf_item = ${setting_map_nref[$conf_item]}"
      config_set "$conf_item" "${setting_map_nref[$conf_item]}"
    fi
  done
}

initialize_ssh_settings() {
    # shellcheck disable=SC2034
    declare -A setting_map=(
      [ssh_credential_user]="$USER"
      [ssh_keyfile_path]="$HOME/.ssh/_hive_known_hosts"
      [ssh_keyfile_hashknownhosts]="yes"
      [ssh_multiplex_enabled]="true"
      [ssh_multiplex_sshconfig]="$HOME/.ssh/config"
      [ssh_multiplex_controlpath]="$HOME/.ssh/_hive_%r@%h.sock"
      [ssh_multiplex_controlpersist]="60m"
      [ssh_multiplex_serveraliveinterval]="300"
    )
    write_conf_items setting_map
}

initialize_prompt_settings() {
    # shellcheck disable=SC2034
    declare -A setting_map=(
      [prompt_ps1_enabled]="true"
      [prompt_output_prefix_enabled]="false"
      [prompt_template_ps1]="'^({CLUSTER}) '"
      [prompt_template_output_prefix]="'({CLUSTER} {DOCKERHOST|cut -d'.' -f1})'"
    )
    write_conf_items setting_map
}

initialize_cluster_settings() {
    # shellcheck disable=SC2034
    declare -A setting_map=(
      [cluster_current]=""
      [cluster_list]=""
    )
    write_conf_items setting_map
}


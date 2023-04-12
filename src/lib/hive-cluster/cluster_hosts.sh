cluster_hosts() {
  jq -r -M -c ".${1}.managers[], .${1}.workers[]" <<< "$(config_get cluster_map)" | tr '\n' ' '
}
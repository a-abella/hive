load_hive_cluster() {
    local current_cluster_parts=( $(config_get cluster_current | sed 's/|/ /g') )
    local cluster_part_names=( name desc mgrs )
    local idx=0
    local sec
    declare -g -A CURRENT_CLUSTER
    if [[ "${#current_cluster_parts[@]}" -gt 0 ]]; then
      for sec in "${cluster_part_names[@]}"; do
          CURRENT_CLUSTER[$sec]="${current_cluster_parts[$idx]}"
          (( ++idx ))
      done
    fi
}
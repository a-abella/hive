load_hive_cluster() {
    declare -g -A CURRENT_CLUSTER
    local current_cluster_name
    current_cluster_name="$(config_get cluster_current)"
    local cluster_map
    cluster_map="$(config_get cluster_map)"
    if [[ "${current_cluster_name// }" && "${cluster_map// }"  ]] && jq empty <<< "$cluster_map"; then
      local current_cluster_json
      if current_cluster_json="$( jq -e ".\"$current_cluster_name\"" <<< "$cluster_map" )"; then
        local current_cluster_parts=()
        current_cluster_parts+=( "$current_cluster_name" )
        current_cluster_parts+=( "$( jq -re '.desc' <<< "$current_cluster_json")" )
        current_cluster_parts+=( "$( jq -re '.managers[]' <<< "$current_cluster_json")" )
        local cluster_part_names=( name desc mgrs )
        local idx=0
        local sec
        if [[ "${#current_cluster_parts[@]}" -gt 0 ]]; then
          for sec in "${cluster_part_names[@]}"; do
              # shellcheck disable=SC2034
              CURRENT_CLUSTER[$sec]="${current_cluster_parts[$idx]}"
              (( ++idx ))
          done
        fi
        :
      else
        fmt_echo "ERROR: cluster with name $current_cluster_name not found in saved cluster_map"
        false
      fi
    else
      return 0
    fi
}
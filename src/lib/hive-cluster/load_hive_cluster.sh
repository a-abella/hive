load_hive_cluster() {
    local current_cluster_parts=( $(config_get cluster_current | sed 's/|/ /g') )
    local cluster_part_names=( cluster name nodetype dockerhost )
    local idx=0
    local sec
    declare -g -A CURRENT_CLUSTER
    for sec in "${cluster_part_names[@]}"; do
        CURRENT_CLUSTER[$sec]="${current_cluster_parts[$idx]}"
        (( ++idx ))
    done
}
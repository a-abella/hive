load_hive_context() {
    local current_context_parts=( $(config_get context_current | sed 's/|/ /g') )
    local context_part_names=( cluster name nodetype dockerhost )
    local idx=0
    local sec
    declare -g -A CURRENT_CONTEXT
    for sec in "${context_part_names[@]}"; do
        CURRENT_CONTEXT[$sec]="${current_context_parts[$idx]}"
        (( ++idx ))
    done
}
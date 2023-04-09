validate_cluster_host() {
    local HOST_PATTERN="^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))*$"
    [[ "$1" =~ $HOST_PATTERN ]] || echo "cluster node hostname must be a valid DNS hostname or IP address"
}
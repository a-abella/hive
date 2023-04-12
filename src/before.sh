## before hook
##
## Any code here will be placed inside a `before_hook()` function and called
## before running any command (but after processing its arguments).
##
## You can safely delete this file if you do not need it.
#echo "==[ Before Hook Called ]=="
dbg_echo "action: $action"
# inspect_args
if [[ $DEBUG -gt 1 ]]; then
  ( set -o posix ; set | sed -e 's/^/_before__/' )
fi

# create settigns file + insert keys/descs/defaults
load_settings all

# shellcheck disable=SC2168

# handle required settings for some actions
case "$action" in
  "config init" | "config show" | "config ssh")
    :
  ;;
  *)
    # error out if cluster(s) not in settings and using an action that requires it
    local current_cluster_name cluster_map
    current_cluster_name="$(config_get cluster_current)"
    cluster_map="$(config_get cluster_map)"
    if [[ ! "${current_cluster_name// }" || ! "${cluster_map// }" ]]; then
      echo "Cluster data missing from $CONFIG_FILE"
      fmt_echo "Try running 'hive config init'"
      false
    fi
  ;;
esac
load_hive_cluster

# DOCKER_HOST define
if [[ "${CURRENT_CLUSTER[name]// }" ]]; then
  ## save current DOCKER_HOST
  export OLD_DOCKER_HOST="$DOCKER_HOST"
  ## set DOCKER_HOST from mgrs
  # shellcheck disable=SC2155
  export DOCKER_HOST="ssh://$(select_manager "${CURRENT_CLUSTER[mgrs]}")"
fi
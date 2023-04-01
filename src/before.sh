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

load_settings all

## sets ${CURRENT_CLUSTER[name|desc|mgs]}
load_hive_cluster

## before hook
##
## Any code here will be placed inside a `before_hook()` function and called
## before running any command (but after processing its arguments).
##
## You can safely delete this file if you do not need it.
echo "==[ Before Hook Called ]=="
dbg_echo "action: $action"
inspect_args
if [[ $DEBUG -gt 1 ]]; then
  ( set -o posix ; set | sed -e 's/^/_before__/' )
fi

load_settings all

if ! config_has_key cluster_current ; then
  case "$action" in
    "config init" )
      :
    ;;
    * )
      echo
      fmt_echo "Missing settings from $(basename "$CONFIG_FILE")"
      fmt_echo "Settings are stored and sourced from local settings files in the following order of precedence:"
      fmt_echo "  - \$PWD/.hive-settings.ini"
      fmt_echo "  - \$HOME/.hive-settings.ini"
      fmt_echo "Run 'hive config init' to initialize $(basename "$CONFIG_FILE")"
      echo
      exit 1
    ;;
  esac
fi

## sets ${CURRENT_CLUSTER[name|desc|mgs]}
load_hive_cluster

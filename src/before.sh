## before hook
##
## Any code here will be placed inside a `before_hook()` function and called
## before running any command (but after processing its arguments).
##
## You can safely delete this file if you do not need it.
echo "==[ Before Hook Called ]=="
inspect_args

if (( DEBUG )); then
  ( set -o posix ; set | sed -e 's/^/_before__/' )
fi

if config_has_key context_current ; then
  load_hive_context
else
  case "$action" in
    "config init" | "config reload" )
      :
      ;;
    * )
      fmt_echo "Unable to load context from $CONFIG_FILE"
      fmt_echo "Run '$0 config init' or '$0 config reload -f {config_file}' to initialize $CONFIG_FILE"
      false
      ;;
  esac
fi
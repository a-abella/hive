# echo "# this file is located in 'src/config_show_command.sh'"
# echo "# code for 'hive config show' goes here"
# echo "# you can edit it freely and regenerate (it will not be overwritten)"
# inspect_args

echo
echo "# Using settings file: $CONFIG_FILE"
echo
# shellcheck disable=SC2086
exec $VIMRUNTIME/macros/less.sh "$CONFIG_FILE"
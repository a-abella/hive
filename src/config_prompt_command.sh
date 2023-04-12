# echo "# this file is located in 'src/config_prompt_command.sh'"
# echo "# code for 'hive config prompt' goes here"
# echo "# you can edit it freely and regenerate (it will not be overwritten)"
# inspect_args

case "${args[TOGGLE]}" in
  enable)
    echo "export HIVE_OLD_PS1=\"\$PS1\"; PS1=\"(hive|\$($(realpath -s "$0") config cluster show -f name)) \$PS1\""
  ;;
  disable)
    echo "PS1=\"\$HIVE_OLD_PS1\"; unset HIVE_OLD_PS1"
  ;;
esac
echo "# embed this command in 'eval', like 'eval \$(hive config prompt enable|disable)'"

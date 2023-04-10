# echo "# this file is located in 'src/config_cluster_show_command.sh'"
# echo "# code for 'hive config cluster show' goes here"
# echo "# you can edit it freely and regenerate (it will not be overwritten)"
# inspect_args

case "${args[--field]}" in
  name)
    echo "${CURRENT_CLUSTER[name]}"
  ;;
  description)
    echo "${CURRENT_CLUSTER[desc]}"
  ;;
  managers)
    echo "${CURRENT_CLUSTER[mgrs]}"
  ;;
  all)
    jq ".${CURRENT_CLUSTER[name]} += {\"name\": \"${CURRENT_CLUSTER[name]}\"}" <<< "$(config_get cluster_map)" | jq -M ".${CURRENT_CLUSTER[name]}"
  ;;
  *)
    fmt_echo "ERROR: unknown case '${args[--field]}'"
    false
  ;;
esac
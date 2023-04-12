cluster_merge() {
  local all_clusters
  all_clusters="$(config_get cluster_map)"
  if [[ ! "${all_clusters// }" ]]; then
    all_clusters="{}"
  fi
  local this_cluster="$1"
  dbg_echo "all_clusters=$all_clusters"
  dbg_echo "this_cluster=$this_cluster"
  local merged_clusters
  merged_clusters="$( jq -s -c -M '.[0] * .[1]' <(echo "$all_clusters") <(echo "$this_cluster") )"
  echo "$merged_clusters"
}
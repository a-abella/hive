cluster_build() {
  # format managers
  if [[ "${3// }" ]]; then
    local mgrs
    mgrs="\"$(joinstr '","' "$(tr ',' ' ' <<< "$3")")\""
  fi
  if [[ "${4// }" ]]; then
    local wrks
    wrks="\"$(joinstr '","' "$(tr ',' ' ' <<< "$4")")\""
  fi
  local j="{\"$1\": {\"description\": \"$2\", \"managers\": [$mgrs], \"workers\": [$wrks]}}"
  echo "$j"
}
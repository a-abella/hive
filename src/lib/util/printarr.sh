printarr() { 
    declare -n __p="$1"
    for k in "${!__p[@]}"; do
        printf "%s=%s\n" "$k" "${__p[$k]}"
    done
}
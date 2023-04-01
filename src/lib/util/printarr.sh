printarr() { 
    declare -n __p="$1"
    for k in "${!__p[@]}"; do
        printf "%s[%s]=%s\n" "$1" "$k" "${__p[$k]}"
    done
}
dbg_echo() {
  (( DEBUG )) && while IFS= read -r line ; do echo "DEBUG | $line" ;  done <<< "$*" || true
}
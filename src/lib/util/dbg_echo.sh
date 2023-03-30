dbg_echo() {
  (( DEBUG )) && echo "DEBUG | $*" || true
}
select_manager() {
  local mgrs
  mgrs=( $1 )
  echo "${mgrs[ $RANDOM % ${#mgrs[@]} ]}"
}
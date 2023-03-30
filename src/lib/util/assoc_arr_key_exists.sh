assoc_arr_key_exists() {
  if [ "$2" != in ]; then
    echo "assoc_arr_key_exists - Incorrect usage."
    echo "Correct usage: assoc_arr_key_exists {key} in {array}"
    return
  fi   
  eval '[ ${'$3'[$1]+_} ]'
}
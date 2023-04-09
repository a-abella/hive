## [@bashly-upgrade validations]
validate_file_exists() {
  # shellcheck disable=SC2001
  [[ -f "$(sed "s%^~%$HOME%" <<< "$1")" ]] || echo "must be an existing file"
}

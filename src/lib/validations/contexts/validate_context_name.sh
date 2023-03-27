validate_context_name() {
    local NAME_PATTERN="^[a-zA-Z0-9+_-]$"
    [[ "$1" =~ $NAME_PATTERN ]] || echo "context name must match regexp $NAME_PATTERN"
}
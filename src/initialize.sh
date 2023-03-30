## Code here runs inside the initialize() function
## Use it for anything that you need to run before any other function, like
## setting environment variables:
## CONFIG_FILE=settings.ini
##
## Feel free to empty (but not delete) this file.
if [[ $DEBUG -gt 1 ]]; then
    set -xv
fi

## Possible settings file locations in descending priority
settings_locs=( "$PWD" "$HOME" )
for i in "${!settings_locs[@]}"; do
  cur="${settings_locs[$i]}/.hive-settings.ini"
  if [[ -f "$cur" || "$i" -eq "$(( ${#settings_locs[@]} - 1 ))" ]]; then
    dbg_echo "using path $cur"
    CONFIG_FILE="${cur}"
    break
  fi
done

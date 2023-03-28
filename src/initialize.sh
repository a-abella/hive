## Code here runs inside the initialize() function
## Use it for anything that you need to run before any other function, like
## setting environment variables:
## CONFIG_FILE=settings.ini
##
## Feel free to empty (but not delete) this file.
if (( DEBUG )); then
    set -xv
fi
CONFIG_FILE="${HIVE_SETTINGS}"
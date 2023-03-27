
load_settings() {
    ## Load settings file if it exists
    ## Initialize settings file if does not exist
    local SETTINGS_FILE="$HOME/.hive-settings.ini"
    if [ ! -f "${SETTINGS_FILE}" ]; then
        initialize_default_settings
    fi
}
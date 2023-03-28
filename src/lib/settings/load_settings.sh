
load_settings() {
    ## Load settings file if it exists
    ## Initialize settings file if does not exist
    if [ ! -f "$CONFIG_FILE" ]; then
        initialize_settings
    fi
    
    case "$action" in
      "config init" )
        :
      ;;
      "config load"* | "config reload"* )
        :
      ;;
      * )
        :
      ;;
    esac
}
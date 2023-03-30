
load_settings() {
    ## initialize any missing settings
    initialize_settings all
    
    case "$action" in
      "config init" )
        :
      ;;
      "config load"* | "config reload" )
        :
      ;;
      * )
        :
      ;;
    esac
}
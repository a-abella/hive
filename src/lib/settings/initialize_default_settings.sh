
initialize_default_settings() {
    config_init
    initialize_ssh_settings
    initialize_prompt_settings
    initialize_context_settings
}

initialize_ssh_settings() {
    config_set ssh_credential_user "$USER"
    config_set ssh_multiplex_enabled "true"
    config_set ssh_multiplex_sshconfig "$HOME/.ssh/config"
    config_set ssh_multiplex_controlpath "$HOME/.ssh/%r@%h.sock"
    config_set ssh_multiplex_controlpersist "60m"
    config_set ssh_multiplex_serveraliveinterval "300"
}

initialize_prompt_settings() {
    config_set prompt_enabled "true"
    config_set prompt_template "^({CLUSTER}|{CONTEXT}) "
}

initialize_context_settings() {
    config_set context_current ""
    config_set context_list ""
}


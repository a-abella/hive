# shellcheck disable=SC2168
echo "# this file is located in 'src/config_init_command.sh'"
echo "# code for 'hive config init' goes here"
echo "# you can edit it freely and regenerate (it will not be overwritten)"
inspect_args

config_eval() {
  dbg_echo "CURRENT_CLUSTER_LEN=${#CURRENT_CLUSTER[@]}"
  declare -A user_input
  if [[ ! "${CURRENT_CLUSTER[*]}" ]]; then
    echo
    dbg_echo "running config_init_cluster"
    config_init_cluster
    local RAN_INIT_CLUSTER=1
  fi
  echo; config_init_ssh
  echo; config_init_prompt
}

config_init_cluster() {
  fmt_echo "Define your first cluster!"
  echo
  fmt_echo "Set an identifying cluster name"
  read -p "  name: " user_input[cluster_name]
  
  echo
  fmt_echo "Hive needs to know a Swarm manager hostname or address belonging to this cluster to interact with services and nodes; more managers can be added or autodiscovered later"
  echo
  fmt_echo "Set a manager hostname or address"
  read -p "  manager: " user_input[cluster_manager]
  echo
  :
}

config_init_ssh() {
  fmt_echo "Tune SSH settings!"
  echo
  fmt_echo "Hive communicates with Docker nodes using ssh with private-key authentication; the provided ssh user must be present on all docker systems in the Swarm cluster, and the user must have access to each node's local docker socket"
  echo
  fmt_echo "SSH credential settings"
  read -p "  ssh user [$USER]: " user_input[ssh_user]
  read -p "  ssh private key (default ssh client key search behavior if left blank): " user_input[ssh_identity]
  echo
  fmt_echo "Hive can handle some ssh quality-of-life configurations like managing host_keys and autoconfiguring multiplexing; reasonable defaults are provided for all configuration options"
  echo
  fmt_echo "SSH config settings"
  read -p "  ssh config path [$HOME/.ssh/config]: " user_input[ssh_config]
  read -p "  enable ssh multiplexing? [Y/n]: " user_input[ssh_multiplex_enable]
  echo
  fmt_echo "SSH multiplexing behavior can be fine tuned; for more information see \`man ssh_config\`"
  fmt_echo "Even if you disabled multiplexing in the last step, these settings will be saved for later"
  echo
  fmt_echo "SSH multiplex settings"
  read -p "  ssh multiplex ControlPath [$(config_get ssh_multiplex_controlpath)]: " user_input[ssh_controlpath]
  read -p "  ssh multiplex ControlPersist [$(config_get ssh_multiplex_controlpersist)]: " user_input[ssh_controlpersist]
  read -p "  ssh multiplex ServerAliveInterval [$(config_get ssh_multiplex_serveraliveinterval)]: " user_input[ssh_aliveinterval]
  echo
  fmt_echo "SSH host_keys can be automatically pruned and imported from discovered cluster nodes, useful if nodes are recreated during system upgrades or if there are too many nodes to manually accept host_keys for"
  echo
  fmt_echo "SSH host_keys settings"
  read -p "  ssh custom KeyFile path [$(config_get ssh_keyfile_path)]: " user_input[ssh_keyfile]
  default_hsk="$(config_get ssh_keyfile_hashknownhosts)"
  if [[ "$default_hsk" =~ ^[yY][eE][sS]$ ]]; then
    default_hsk="Y/n"
  elif [[ "$default_hsk" =~ ^[nN][oO]$ ]]; then
    default_hsk="y/N"
  else
    fmt_echo "ERROR: invalid config \"ssh_keyfile_hashknownhosts = $default_hsk\" in $CONFIG_FILE"
  fi
  read -p "  ssh KeyFile HashKnownHosts [$default_hsk]: " user_input[ssh_hashknownhosts]
  echo
  fmt_echo "The following SSH configurations will be applied based on your selections:"
  echo
  echo "# The file ${user_input[ssh_config]}_hive will be created"
  echo "# with the following content:"
  local SSH_CONFIG_HIVE
  SSH_CONFIG_HIVE="Host ${user_input[cluster_manager]}
  User ${user_input[ssh_user]}
  IdentityFile ${user_input[ssh_identity]}
  ControlMaster $([[ "${user_input[ssh_multiplex_enable]}" =~ ^[yY][eE]?[sS]?$ ]] && echo Auto || echo no)
  ControlPath ${user_input[ssh_multiplex_controlpath]}
  ControlPersist ${user_input[ssh_multiplex_controlpersist]}
  ServerAliveInterval ${user_input[ssh_multiplex_aliveinterval]}"
  echo
  cat <<< "$SSH_CONFIG_HIVE"
}

config_init_prompt() {
  :
}

#clear
fmt_echo "Initializing $CONFIG_FILE"
config_eval


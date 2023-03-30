# shellcheck disable=SC2168
echo "# this file is located in 'src/config_init_command.sh'"
echo "# code for 'hive config init' goes here"
echo "# you can edit it freely and regenerate (it will not be overwritten)"
inspect_args

# clear



local sect
for sect in cluster_ \
            ssh_credential_ ; do
  :
done

print_sep

for sect in ssh_multiplex_ \
            ssh_keyfile_ \
            prompt_ ; do
  :
done
            
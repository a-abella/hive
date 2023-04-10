## after hook
##
## Any code here will be placed inside an `after_hook()` function and called
## after running any command.
##
## You can safely delete this file if you do not need it.
# echo "==[ After Hook Called ]=="
# inspect_args

if [[ $DEBUG -gt 1 ]]; then
    ( set -o posix ; set | sed -e 's/^/_after__/' )
fi

## unset DOCKER_HOST
unset DOCKER_HOST

## restore OLD_DOCKER_HOST
[[ "${OLD_DOCKER_HOST// }" ]] && export DOCKER_HOST="$OLD_DOCKER_HOST" && unset OLD_DOCKER_HOST
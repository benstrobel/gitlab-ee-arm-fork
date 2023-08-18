# (source this file to export definitions)

_generate_gitlab_ctl_completion_cache() {
  _gitlab_ctl_completion_cache=$(gitlab-ctl help | awk '/^  [a-z]/ {print $1}')
}

_generate_gitlab_ctl_services_cache() {
  _gitlab_ctl_services_cache=$(gitlab-ctl status | awk '{sub(/:/, "", $2); print $2}')
}

_gitlab_ctl_completion() {
  local cur_word="${COMP_WORDS[COMP_CWORD]}"
  local prev_word="${COMP_WORDS[COMP_CWORD-1]}"
  local options=""

  # Generate command completion cache if it's empty
  if [[ -z "$_gitlab_ctl_completion_cache" ]]; then
    _generate_gitlab_ctl_completion_cache
  fi

  # Generate completion options based on the command and current word
  if [[ "$prev_word" == "gitlab-ctl" ]]; then
    options="$_gitlab_ctl_completion_cache"
  elif [[ "$prev_word" == @(start|stop|restart|status) ]]; then
    if [[ -z "$_gitlab_ctl_services_cache" ]]; then
      _generate_gitlab_ctl_services_cache
    fi
    options="$_gitlab_ctl_services_cache"
  else
    local subcommand_options
    subcommand_options=$(gitlab-ctl help "$prev_word" | awk '/^ {4}[^ ]/ {print $1}')
    options="$subcommand_options"
  fi

  # Complete the current word with the available options
  COMPREPLY=($(compgen -W "$options" -- "$cur_word"))
}

complete -F _gitlab_ctl_completion gitlab-ctl

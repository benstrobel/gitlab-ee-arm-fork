# (source this file to export definitions)

_gitlab-rails_completion() {
  local cur_word="${COMP_WORDS[COMP_CWORD]}"
  local prev_word="${COMP_WORDS[COMP_CWORD-1]}"
  local options=""

  # gitlab-rails is a wrapper for running rails in the gitlab application.
  # Many of the rails commands you would not want to run on a GitLab server.
  # These are the only ones mentioned in the GitLab documentation, or are safe.
  if [[ "$prev_word" == "gitlab-rails" ]]; then
    options="console dbconsole runner"
  fi

  if [[ "$prev_word" == "dbconsole" ]]; then
    options="--database main"
  fi

  # Complete the current word with the available options
  COMPREPLY=($(compgen -W "$options" -- "$cur_word"))
}

complete -F _gitlab-rails_completion gitlab-rails

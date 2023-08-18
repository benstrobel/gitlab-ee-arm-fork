# (source this file to export definitions)

# This can take >15 seconds. May want to call it after sourcing
_generate_gitlab_rake_completion_cache() {
  local delimiter="###"  # Custom delimiter

  # Generate completion options dynamically and cache them
  _gitlab_rake_completion_cache=$(gitlab-rake --tasks | awk -v d="$delimiter" '{gsub(":", d, $2); print $2}')
}

_gitlab_rake_completion() {
  local cur_word="${COMP_WORDS[COMP_CWORD]}"
  local prev_word="${COMP_WORDS[COMP_CWORD-1]}"
  local options=""

  local delimiter="###"  # Custom delimiter

  # Set COMP_WORDBREAKS to include a colon
  COMP_WORDBREAKS="${COMP_WORDBREAKS/:}"

  # Check if cache is empty
  if [[ -z "$_gitlab_rake_completion_cache" ]]; then
    _generate_gitlab_rake_completion_cache
  fi

  # Replace the custom delimiter with a colon for display
  options="${_gitlab_rake_completion_cache//$delimiter/:}"

  # Handle cases where previous word includes a colon using regex comparison
  # TODO: This still makes repeated calls to gitlab-rake for the tasks
  if [[ "$prev_word" =~ .*:.* ]]; then
    prev_word="${prev_word//$delimiter/:}"
    options="$(gitlab-rake --tasks | awk -v d="$delimiter" -v p="$prev_word" '$2 ~ p {gsub(":", d, $2); print $2}')"
  fi

  COMPREPLY=($(compgen -W "$options" -- "$cur_word"))
}

complete -F _gitlab_rake_completion gitlab-rake

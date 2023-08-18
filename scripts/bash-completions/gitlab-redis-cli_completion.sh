# (source this file to export definitions)

_gitlab-redis-cli_completion() {
  local cur_word prev_word
  cur_word="${COMP_WORDS[COMP_CWORD]}"
  prev_word="${COMP_WORDS[COMP_CWORD-1]}"

  COMPREPLY=()

  case $prev_word in
    -h)
      # Add logic to complete known hosts
      COMPREPLY=( $(compgen -W "localhost 127.0.0.1" -- "$cur_word") )
      ;;
    -s)
      # Add logic to complete socket files
      COMPREPLY=( $(compgen -W "6379" -- "$cur_word") )
      ;;
    *)
      # Generate completion suggestions based on redis-cli --help
      COMPREPLY=( $( compgen -W "$( gitlab-redis-cli --help |& awk '/^ *-/ {print $1}')" -- "$cur_word" ) )
      ;;
  esac
}

complete -F _gitlab-redis-cli_completion gitlab-redis-cli

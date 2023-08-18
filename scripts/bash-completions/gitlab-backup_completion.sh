# (source this file to export definitions)

_gitlab-backup_completion() {
  local cur_word="${COMP_WORDS[COMP_CWORD]}"
  local prev_word="${COMP_WORDS[COMP_CWORD-1]}"
  local options=""

#TODO: set COMP_WORDBREAKS="${COMP_WORDBREAKS/=}" and add completion for SKIP=

  if [[ "$prev_word" == "gitlab-backup" ]]; then
    options="create restore"
  fi

  # GitLab Backup's create/restore options are documented at
  # https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html

  if [[ "$prev_word" == "create" ]]; then
    read -r -d '' options << 'OPTS'
      STRATEGY=copy BACKUP= GZIP_RSYNCABLE=yes SKIP=
      GITLAB_BACKUP_MAX_CONCURRENCY= GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY=
      INCREMENTAL= PREVIOUS_BACKUP= REPOSITORY_STORAGES= REPOSITORIES_PATHS=
      SKIP_REPOSITORIES_PATHS= DIRECTORY=
OPTS
  fi

  if [[ "$prev_word" == "restore" ]]; then
    read -r -d '' options << 'OPTS'
    BACKUP= SKIP= REPOSITORIES_STORAGES= REPOSITORIES_PATHS=
    SKIP_REPOSITORIES_PATHS=
OPTS
  fi

  # Complete the current word with the available options
  COMPREPLY=($(compgen -W "$options" -- "$cur_word"))
}

complete -F _gitlab-backup_completion gitlab-backup

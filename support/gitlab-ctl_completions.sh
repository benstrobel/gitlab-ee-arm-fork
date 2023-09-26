!#/bin/bash

_gitlab-ctl_completions()
{

    # return if at least one arg has already been typed
    if [ "${#COMP_WORDS[@]}" != "2" ]; then
        return
    fi

    # Regex looks for lines:
    #  1. Starting with 0 or more whitespaces
    #  2. Followed by at least one lowercase word
    #  3. Ending with zero or more lowercase words separate by dashes.
    COMPREPLY=($(compgen -W \
        "$(gitlab-ctl --help \
        | awk '/^ *[a-z]+(-[a-z]*)*$/' \
        | sed 's/ //g' \
        )" -- "${COMP_WORDS[1]}"))
}

complete -F _gitlab-ctl_completions gitlab-ctl
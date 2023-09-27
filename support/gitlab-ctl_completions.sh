#!/bin/bash

_gitlab-ctl_completions()
{

    # return if at least one arg has already been typed
    if [ "${#COMP_WORDS[@]}" != "2" ]; then
        return
    fi

    # Check if gitlab-ctl compspec already exists
    if [ -z "${GITLAB_CTL_CMDS}" ]; then
        # if not, register them.
        GITLAB_CTL_CMDS="$(gitlab-ctl --help \
            # Regex looks for lines:
            #  1. Starting with 0 or more whitespaces
            #  2. Followed by at least one lowercase word
            #  3. Ending with zero or more lowercase words 
            #     separated by dashes.
            | awk '/^ *[a-z]+(-[a-z]*)*$/ { gsub(/ /, ""); print }'
            )"
    fi

    COMPREPLY=($(compgen -W "${GITLAB_CTL_CMDS}" -- "${COMP_WORDS[1]}"))
}

complete -F _gitlab-ctl_completions gitlab-ctl

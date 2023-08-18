# Command-line TAB completions for some GitLab Omnibus commands

Basic completions for common GitLab command-line tools. They are intended for 
use from the GitLab Omnibus server's system shell, rather than developer
workstations. Consequently, these are done _without_ the use of the Bash 
Completion Framework, to remove the dependency (and because servers may not
necessarily have that framework installed or activated for the root user).

Some GitLab commands are quite verbose, especially rake tasks, and it is nice to 
have this affordance, particularly during troubleshooting.

## Usage

Load the initialization script from a logged-in shell: `source init.sh`. 
Afterwards, <kbd>TAB</kbd> completion will be available for GitLab Omnibus
command-line tools.

You can speed up the first completion run by telling `init.sh` to do the 
completions lookups when it loads: just supply it with a shell argument
(anynon-null value will work): `source init.sh e`.  The available tasks are
cached to memory after the first run.

## Caveats

- This is a first-iteration, MVC prototype. Basic completion works, but arguments for options is incomplete
- Tested on a single-server Omnibus. For multi-node HA, you would need to run these on the correct node
- The `_gitlab-rake_completion` function can be slow on first run, while it looksup the available rake tasks.
- Completion for most commands will only work for users with permisson to run the commands to inspect the available options. This is most commonly the `root` or `git` users.

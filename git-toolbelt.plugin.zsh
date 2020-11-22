# ------------------------------------------------------------------------------
# Description
# -----------
#
#  Completion script for git-toolbelt (https://github.com/nvie/git-toolbelt).
#
#  This depends on and reuses some of the internals of the _git completion
#  function that ships with zsh itself. It will not work with the _git that ships
#  with git.
#
# ------------------------------------------------------------------------------
# Authors
# -------
#
#  * Werner Stein (https://github.com/wstein)
#
# ------------------------------------------------------------------------------
# Inspirations
# -----------
#
#  * git-toolbelt (https://github.com/nvie/git-toolbelt)
#  * ohmyzsh git-extras plugin (https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git-extras)
#
# ------------------------------------------------------------------------------


# Internal functions
# These are a lot like their __git_* equivalents inside _git

__gitex_command_successful () {
  if (( ${#*:#0} > 0 )); then
    _message 'not a git repository'
    return 1
  fi
  return 0
}

__gitex_commits() {
    declare -A commits
    git log --oneline -15 | sed 's/\([[:alnum:]]\{7\}\) /\1:/' | while read commit
    do
        hash=$(echo $commit | cut -d':' -f1)
        commits[$hash]="$commit"
    done
    local ret=1
    _describe -t commits commit commits && ret=0
}

__gitex_remote_names() {
    local expl
    declare -a remote_names
    remote_names=(${(f)"$(_call_program remotes git remote 2>/dev/null)"})
    __git_command_successful || return
    _wanted remote-names expl remote-name compadd $* - $remote_names
}

__gitex_tag_names() {
    local expl
    declare -a tag_names
    tag_names=(${${(f)"$(_call_program tags git for-each-ref --format='"%(refname)"' refs/tags 2>/dev/null)"}#refs/tags/})
    __git_command_successful || return
    _wanted tag-names expl tag-name compadd $* - $tag_names
}


__gitex_branch_names() {
    local expl
    declare -a branch_names
    branch_names=(${${(f)"$(_call_program branchrefs git for-each-ref --format='"%(refname)"' refs/heads 2>/dev/null)"}#refs/heads/})
    __git_command_successful || return
    _wanted branch-names expl branch-name compadd $* - $branch_names
}

__gitex_specific_branch_names() {
    local expl
    declare -a branch_names
    branch_names=(${${(f)"$(_call_program branchrefs git for-each-ref --format='"%(refname)"' refs/heads/"$1" 2>/dev/null)"}#refs/heads/$1/})
    __git_command_successful || return
    _wanted branch-names expl branch-name compadd - $branch_names
}

__gitex_chore_branch_names() {
    __gitex_specific_branch_names 'chore'
}

__gitex_feature_branch_names() {
    __gitex_specific_branch_names 'feature'
}

__gitex_refactor_branch_names() {
    __gitex_specific_branch_names 'refactor'
}

__gitex_bug_branch_names() {
    __gitex_specific_branch_names 'bug'
}

__gitex_submodule_names() {
    local expl
    declare -a submodule_names
    submodule_names=(${(f)"$(_call_program branchrefs git submodule status | awk '{print $2}')"})  # '
    __git_command_successful || return
    _wanted submodule-names expl submodule-name compadd $* - $submodule_names
}


__gitex_author_names() {
    local expl
    declare -a author_names
    author_names=(${(f)"$(_call_program branchrefs git log --format='%aN' | sort -u)"})
    __git_command_successful || return
    _wanted author-names expl author-name compadd $* - $author_names
}

# subcommands
_git-authors() {
    _arguments  -C \
        '(--list -l)'{--list,-l}'[show authors]' \
        '--no-email[without email]' \
}

_git-bug() {
    local curcontext=$curcontext state line ret=1
    declare -A opt_args

    _arguments -C \
        ': :->command' \
        '*:: :->option-or-argument' && ret=0

    case $state in
        (command)
            declare -a commands
            commands=(
                'finish:merge bug into the current branch'
            )
            _describe -t commands command commands && ret=0
            ;;
        (option-or-argument)
            curcontext=${curcontext%:*}-$line[1]:
            case $line[1] in
                (finish)
                    _arguments -C \
                        ':branch-name:__gitex_bug_branch_names'
                    ;;
                -r|--remote )
                    _arguments -C \
                        ':remote-name:__gitex_remote_names'
                    ;;
            esac
            return 0
    esac

    _arguments \
        '(--remote -r)'{--remote,-r}'[setup remote tracking branch]'
}


_git-changelog() {
    _arguments \
        '(-l --list)'{-l,--list}'[list commits]' \
}

_git-chore() {
    local curcontext=$curcontext state line ret=1
    declare -A opt_args

    _arguments -C \
        ': :->command' \
        '*:: :->option-or-argument' && ret=0

    case $state in
        (command)
            declare -a commands
            commands=(
                'finish:merge and delete the chore branch'
            )
            _describe -t commands command commands && ret=0
            ;;
        (option-or-argument)
            curcontext=${curcontext%:*}-$line[1]:
            case $line[1] in
                (finish)
                    _arguments -C \
                        ':branch-name:__gitex_chore_branch_names'
                    ;;
                -r|--remote )
                    _arguments -C \
                        ':remote-name:__gitex_remote_names'
                    ;;
            esac
            return 0
    esac

    _arguments \
        '(--remote -r)'{--remote,-r}'[setup remote tracking branch]'
}


_git-contrib() {
    _arguments \
        ':author:__gitex_author_names'
}


_git-count() {
    _arguments \
        '--all[detailed commit count]'
}

_git-create-branch() {
    local curcontext=$curcontext state line
    _arguments -C \
        ': :->command' \
        '*:: :->option-or-argument'

    case "$state" in
        (command)
            _arguments \
                '(--remote -r)'{--remote,-r}'[setup remote tracking branch]'
            ;;
        (option-or-argument)
            curcontext=${curcontext%:*}-$line[1]:
            case $line[1] in
                -r|--remote )
                    _arguments -C \
                        ':remote-name:__gitex_remote_names'
                    ;;
            esac
    esac
}

_git-delete-branch() {
    _arguments \
        ':branch-name:__gitex_branch_names'
}


_git-delete-submodule() {
    _arguments \
        ':submodule-name:__gitex_submodule_names'
}


_git-delete-tag() {
    _arguments \
        ':tag-name:__gitex_tag_names'
}


_git-effort() {
    _arguments \
        '--above[ignore file with less than x commits]'
}


_git-extras() {
    local curcontext=$curcontext state line ret=1
    declare -A opt_args

    _arguments -C \
        ': :->command' \
        '*:: :->option-or-argument' && ret=0

    case $state in
        (command)
            declare -a commands
            commands=(
                'update:update git-extras'
            )
            _describe -t commands command commands && ret=0
            ;;
    esac

    _arguments \
        '(-v --version)'{-v,--version}'[show current version]'
}


_git-feature() {
    local curcontext=$curcontext state line ret=1
    declare -A opt_args

    _arguments -C \
        ': :->command' \
        '*:: :->option-or-argument' && ret=0

    case $state in
        (command)
            declare -a commands
            commands=(
                'finish:merge feature into the current branch'
            )
            _describe -t commands command commands && ret=0
            ;;
        (option-or-argument)
            curcontext=${curcontext%:*}-$line[1]:
            case $line[1] in
                (finish)
                    _arguments -C \
                        ':branch-name:__gitex_feature_branch_names'
                    ;;
                -r|--remote )
                    _arguments -C \
                        ':remote-name:__gitex_remote_names'
                    ;;
            esac
            return 0
    esac

    _arguments \
        '(--remote -r)'{--remote,-r}'[setup remote tracking branch]'
}

_git-graft() {
    _arguments \
        ':src-branch-name:__gitex_branch_names' \
        ':dest-branch-name:__gitex_branch_names'
}

_git-guilt() {
    _arguments -C \
        '(--email -e)'{--email,-e}'[display author emails instead of names]' \
        '(--ignore-whitespace -w)'{--ignore-whitespace,-w}'[ignore whitespace only changes]' \
        '(--debug -d)'{--debug,-d}'[output debug information]' \
        '-h[output usage information]'
}

_git-ignore() {
    _arguments  -C \
        '(--local -l)'{--local,-l}'[show local gitignore]' \
        '(--global -g)'{--global,-g}'[show global gitignore]' \
        '(--private -p)'{--private,-p}'[show repo gitignore]'
}


_git-ignore() {
    _arguments  -C \
        '(--append -a)'{--append,-a}'[append .gitignore]' \
        '(--replace -r)'{--replace,-r}'[replace .gitignore]' \
        '(--list-in-table -l)'{--list-in-table,-l}'[print available types in table format]' \
        '(--list-alphabetically -L)'{--list-alphabetically,-L}'[print available types in alphabetical order]' \
        '(--search -s)'{--search,-s}'[search word in available types]'
}


_git-merge-into() {
    _arguments '--ff-only[merge only fast-forward]'
    _arguments \
        ':src:__gitex_branch_names' \
        ':dest:__gitex_branch_names'
}

_git-missing() {
    _arguments \
        ':first-branch-name:__gitex_branch_names' \
        ':second-branch-name:__gitex_branch_names'
}


_git-refactor() {
    local curcontext=$curcontext state line ret=1
    declare -A opt_args

    _arguments -C \
        ': :->command' \
        '*:: :->option-or-argument' && ret=0

    case $state in
        (command)
            declare -a commands
            commands=(
                'finish:merge refactor into the current branch'
            )
            _describe -t commands command commands && ret=0
            ;;
        (option-or-argument)
            curcontext=${curcontext%:*}-$line[1]:
            case $line[1] in
                (finish)
                    _arguments -C \
                        ':branch-name:__gitex_refactor_branch_names'
                    ;;
                -r|--remote )
                    _arguments -C \
                        ':remote-name:__gitex_remote_names'
                    ;;
            esac
            return 0
    esac

    _arguments \
        '(--remote -r)'{--remote,-r}'[setup remote tracking branch]'
}


_git-squash() {
    _arguments \
        ':branch-name:__gitex_branch_names'
}

_git-stamp() {
    _arguments  -C \
         '(--replace -r)'{--replace,-r}'[replace stamps with same id]'
}

_git-standup() {
    _arguments -C \
        '-a[Specify the author of commits. Use "all" to specify all authors.]' \
        '-d[Show history since N days ago]' \
        '-D[Specify the date format displayed in commit history]' \
        '-f[Fetch commits before showing history]' \
        '-g[Display GPG signed info]' \
        '-h[Display help message]' \
        '-L[Enable the inclusion of symbolic links]' \
        '-m[The depth of recursive directory search]'
}

_git-summary() {
    _arguments '--line[summarize with lines rather than commits]'
    __gitex_commits
}


_git-undo(){
    _arguments  -C \
        '(--soft -s)'{--soft,-s}'[only rolls back the commit but changes remain un-staged]' \
        '(--hard -h)'{--hard,-h}'[wipes your commit(s)]'
}

zstyle -g existing_user_commands ':completion:*:*:git:*' user-commands

zstyle ':completion:*:*:git:*' user-commands $existing_user_commands \
    current-branch:'Returns the name of the current branch' \
    main-branch:'Returns the name of the default main branch' \
    sha:'Returns the SHA value for the specified object, or the current branch' \
    modified:'Returns a list of locally modified files' \
    modified-since:'Like git-modified, but for printing a list of files that have been modified since master' \
    separator:'Adds a commit with a message of only ---'\''s, so that it visually separates commits' \
    spinoff:'Creates and checks out a new branch starting at and tracking the current branch' \
    push-current:'Pushed the current branch out to origin, and makes sure to setup tracking of the remote branch' \
    is-headless:'Tests if HEAD is pointing to a branch head' \
    local-branches:'Returns a list of local branches in machine-processable style' \
    remote-branches:'Returns a list of remote branches in machine-processable style' \
    active-branches:'Returns a list of active branches in machine-processable style' \
    local-branch-exists:'Tests if the given local branch exists' \
    remote-branch-exists:'Tests if the given remote branch exists' \
    tag-exists:'Tests if the given tag exists' \
    recent-branches:'Returns a list of local branches, ordered by recency' \
    remote-tracking-branch:'Print the name of the remote tracking branch of the current or given local branch name' \
    local-commits:'Returns a list of commits that are still in your local repo, but haven'\''t been pushed to origin' \
    has-local-commits:'Tests local commits still have to be pushed to origin' \
    contains:'Tests if first is merged into second' \
    is-ancestor:'Tests if first is an ancestor of second' \
    stage-all:'Mimics the index / staging area to match the working tree exactly' \
    unstage-all:'Unstages everything. Leaves the working tree intact' \
    undo-merge:'Undo the last merge' \
    undo-commit:'Undo the last commit without loosing any data' \
    cleanup:'Deletes all branches that have already been merged into master or develop' \
    fixup:'Amend all local staged changes into the last commit' \
    fixup-with:'Interactively pick a commit to fixup with' \
    workon:'Convenience command for quickly switching to a branch' \
    delouse:'Rebuild the last commit, but keep the commit message' \
    shatter-by-file:'Splits the last commit into N+1 commits, where N is the number of files in the last commit' \
    commit-to:'Commit a change to a different branch' \
    cherry-pick-to:'Cherry-pick to a different branch' \
    is-repo:'Checks if the current directory is a Git repo' \
    root:'Prints the root location of the working tree' \
    repo:'Prints the location of the Git directory, typically .git' \
    initial-commit:'prints the initial commit for the repo' \
    has-local-changes:'Helper function that determines whether there are local changes' \
    is-clean:'Helper function that determines whether there are local changes' \
    is-dirty:'Helper function that determines whether there are local changes' \
    drop-local-changes:'Drops all local changes, aborting rebase, undoing partial merges, resetting the index and removing any unknown local files' \
    stash-everything:'Stashes the everything, leaving a totally clean working tree' \
    update-all:'Updates all local branch heads to the remote'\''s equivalent' \
    merged:'Shows what local branches have been merged into branch (defaults to master)' \
    unmerged:'Shows what local branches have been merged into branch (defaults to master)' \
    merge-status:'Shows merge status of all local branches against branch (defaults to the main branch)' \
    branches-containing:'Returns a list of branches which contain the specified branch' \
    committer-info:'Shows contribution stats for the given committer' \
    conflicts:'Generates a summary for all local branches that will merge uncleanly' \
    skip:'Skip locally modified file' \
    unskip:'Unskip locally modified file' \
    show-skipped:'Lists all files that are skipped from the index'
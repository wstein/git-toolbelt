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

# ================================================================================

_git-active-branches(){
    _arguments  -C \
        '-a[alias for -s]' \
        '-h[display help message]' \
        '-s[show branches active since <date> (as in '\''git log --since'\'')]'
}

_git-branches-containing() {
    _arguments \
        ':branch-name:__gitex_branch_names'
}

_git-cherry-pick-to() {
    _arguments \
        ':src:__gitex_branch_names' \
        ':dest:__gitex_commits'
}

_git-commit-to() {
    _arguments \
        ':dest:__gitex_branch_names'
}

_git-committer-info(){
    _arguments  -C \
        '-a[Print for all committers]' \
        '-A[Consider all branches (instead of only the current branch)]' \
        '-h[display help message]'
}

zstyle -g existing_user_commands ':completion:*:*:git:*' user-commands

zstyle ':completion:*:*:git:*' user-commands $existing_user_commands \
    active-branches:'returns a list of active branches in machine-processable style' \
    auto-fixup:'experimental' \
    branches-containing:'returns a list of branches which contain the specified branch' \
    cherry-pick-to:'cherry-pick to a different branch' \
    cleanup:'deletes all branches that have already been merged into master or develop, local and remote' \
    commit-to:'commit a change to a different branch' \
    committer-info:'Show contribution stats for any committer matching the given pattern' \
    conflicts:'generates a summary for all local branches that will merge uncleanly' \
    contains:'tests if first is merged into second' \
    current-branch:'returns the name of the current branch' \
    delouse:'rebuild the last commit, but keep the commit message' \
    drop-local-changes:'drops all local changes, aborting rebase, undoing partial merges, resetting the index and removing any unknown local files' \
    fixup-with:'interactively pick a commit to fixup with' \
    fixup:'amend all local staged changes into the last commit' \
    has-local-changes:'helper function that determines whether there are local changes' \
    has-local-commits:'tests local commits still have to be pushed to origin' \
    initial-commit:'prints the initial commit for the repo' \
    is-ancestor:'tests if first is an ancestor of second' \
    is-clean:'helper function that determines whether there are local changes' \
    is-dirty:'helper function that determines whether there are local changes' \
    is-headless:'tests if HEAD is pointing to a branch head' \
    is-repo:'checks if the current directory is a Git repo' \
    local-branch-exists:'tests if the given local branch exists' \
    local-branches:'returns a list of local branches in machine-processable style' \
    local-commits:'returns a list of commits that are still in your local repo, but haven'\''t been pushed to origin' \
    main-branch:'returns the name of the default main branch' \
    merge-status:'shows merge status of all local branches against branch (defaults to the main branch)' \
    merged:'shows what local branches have been merged into branch (defaults to master)' \
    modified-since:'like git-modified, but for printing a list of files that have been modified since master' \
    modified:'returns a list of locally modified files' \
    push-current:'pushed the current branch out to origin, and makes sure to setup tracking of the remote branch' \
    recent-branches:'returns a list of local branches, ordered by recency' \
    remote-branch-exists:'tests if the given remote branch exists' \
    remote-branches:'returns a list of remote branches in machine-processable style' \
    remote-tracking-branch:'print the name of the remote tracking branch of the current or given local branch name' \
    repo:'prints the location of the Git directory, typically .git' \
    root:'prints the root location of the working tree' \
    separator:'adds a commit with a message of only ---'\''s, so that it visually separates commits' \
    sha:'returns the SHA value for the specified object, or the current branch' \
    shatter-by-file:'splits the last commit into N+1 commits, where N is the number of files in the last commit' \
    show-skipped:'lists all files that are skipped from the index' \
    skip:'skip locally modified file' \
    spinoff:'creates and checks out a new branch starting at and tracking the current branch' \
    stage-all:'mimics the index / staging area to match the working tree exactly' \
    stash-everything:'stashes the everything, leaving a totally clean working tree' \
    tag-exists:'tests if the given tag exists' \
    undo-commit:'undo the last commit without loosing any data' \
    undo-merge:'undo the last merge' \
    unmerged:'shows what local branches have been merged into branch (defaults to master)' \
    unskip:'unskip locally modified file' \
    unstage-all:'unstages everything. Leaves the working tree intact' \
    update-all:'updates all local branch heads to the remote'\''s equivalent' \
    workon:'convenience command for quickly switching to a branch' \

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
        hash=$(echo "$commit" | cut -d':' -f1)
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
    _wanted remote-names expl remote-name compadd "$*" - "$remote_names"
}

__gitex_tag_names() {
    local expl
    declare -a tag_names
    tag_names=(${${(f)"$(_call_program tags git for-each-ref --format='"%(refname)"' refs/tags 2>/dev/null)"}#refs/tags/})
    __git_command_successful || return
    _wanted tag-names expl tag-name compadd "$*" - "$tag_names"
}


__gitex_branch_names() {
    local expl
    declare -a branch_names
    branch_names=(${${(f)"$(_call_program branchrefs git for-each-ref --format='"%(refname)"' refs/heads 2>/dev/null)"}#refs/heads/})
    __git_command_successful || return
    _wanted branch-names expl branch-name compadd "$*" - "$branch_names"
}

__gitex_specific_branch_names() {
    local expl
    declare -a branch_names
    branch_names=(${${(f)"$(_call_program branchrefs git for-each-ref --format='"%(refname)"' refs/heads/"$1" 2>/dev/null)"}#refs/heads/$1/})
    __git_command_successful || return
    _wanted branch-names expl branch-name compadd - "$branch_names"
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
    _wanted submodule-names expl submodule-name compadd "$*" - "$submodule_names"
}


__gitex_author_names() {
    local expl
    declare -a author_names
    author_names=(${(f)"$(_call_program branchrefs git log --format='%aN' | sort -u)"})
    __git_command_successful || return
    _wanted author-names expl author-name compadd "$*" - "$author_names"
}

# ==========================================================================

_git-active-branches() {
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

_git-cleanup() {
    _arguments  -C \
        '-h[display help message]' \
        '-l[Local branches only, don'\''t touch the remotes]' \
        '-n[Dry-run]' \
        '-s[Squashed]' \
        '-v[Be verbose (show what'\''s skipped)]' 
}

_git-commit-to() {
    _arguments \
        ':dest:__gitex_branch_names'
}

_git-committer-info() {
    _arguments  -C \
        '-a[Print for all committers]' \
        '-A[Consider all branches (instead of only the current branch)]' \
        '-h[display help message]'
}

_git-conflicts() {
    _arguments  -C \
        '-r[Remote branches (default is only local branches)]' \
        '-q[Be quiet (only report about conflicts)]' \
        '-h[display help message]'
}

_git-contains() {
    _arguments \
        ':first:__gitex_branch_names' \
        ':second:__gitex_branch_names'
}

_git-fixup-with() {
    _arguments -C \
        '-r[When done, trigger an interactive rebase right after]' \
        '-h[display help message]' \
        ':commit:__gitex_commits'
}

_git-is-ancestor() {
    _arguments \
        ':first:__gitex_branch_names' \
        ':second:__gitex_branch_names'
}

_git-is-clean() {
    _arguments -C \
        '-a[Check if any files are marked (un)skipped]' \
        '-h[display help message]' \
        '-i[Check if index is clean]' \
        '-v[Be verbose, print errors to stderr]' \
        '-w[Check if worktree is clean]'
}

_git-is-dirty() {
    _arguments -C \
        '-a[Check if any files are marked (un)skipped]' \
        '-h[display help message]' \
        '-i[Check if index is dirty]' \
        '-v[Be verbose, print errors to stderr]' \
        '-w[Check if worktree is dirty]'
}

_git-last-commit-to-file() {
    _arguments \
        '-h[display help message]' \
        ':files:_files'
}

_git-local-branch-exists() {
    _arguments ':branch:__gitex_branch_names'
}

_git-merge-status() {
    _arguments -C \
        '-h[display help message]' \
        ':branch:__gitex_branch_names'
}

_git-merged() {
    _arguments -C \
        '-h[display help message]' \
        '-u[Show unmerged branches instead of merged branches]' \
        ':branch:__gitex_branch_names'
}

_git-merges-cleanly() {
    _arguments -C \
        '-h[display help message]' \
        '-l[List conflicting files]' \
        ':branch:__gitex_branch_names'
}

_git-modified() {
    _arguments -C \
        '-h[display help message]' \
        '-i[Consider the index, too]' \
        '-q[Be quiet, only return with 0 exit code when files are modified]' \
        '-u[Print only files that are unmerged (files with conflicts)]' \
        ':commit:__gitex_commits'
}

_git-modified-since() {
    _arguments -C \
        '-h[display help message]' \
        '-q[Be quiet, only return with 0 exit code when files are modified]' \
        ':commit:__gitex_commits'
}

_git-push-current() {
    _arguments -C \
        '-f[Force push (will use a lease)]' \
        '-h[display help message]' \
        ':remote:__gitex_remote_names'
}

_git-remote-branch-exists() {
    _arguments -C \
        ':remote:__gitex_remote_names' \
        ':branch:__gitex_branch_names'
}

_git-remote-branches() {
    _arguments -C \
        ':remote:__gitex_remote_names'
}

_git-remote-tracking-branch() {
    _arguments -C \
        '-h[display help message]' \
        ':remote:__gitex_branch_names'
}

_git-repo() {
    _arguments -C \
        '-h[display help message]' \
        '-q[Quiet (only return with exit code 0 if a git repo is found)]'
}

_git-sha() {
    _arguments -C \
        '-h[display help message]' \
        '-q[Be quiet (only return exit code 0 when object exists)]' \
        '-s[Output short SHAs]' 
        # todo list objects
}

_git-show-skipped() {
    _arguments -C \
        '-h[display help message]' \
        '-q[Be quiet (only return exit code 0 when object exists)]'
}

_git-skip() {
    _arguments -C \
        "-a[Skip all locally modified files]" \
        '-q[Be quiet (only return exit code 0 when object exists)]'
}

_git-undo-commit() {
    _arguments -C \
        "-f[Don't keep the commit's changes (destructive)]" \
        '-q[Be quiet (only return exit code 0 when object exists)]'
}

_git-unskip() {
    _arguments -C \
        "-a[Unskip all files]" \
        '-q[Be quiet (only return exit code 0 when object exists)]'
}

_git-workon() {
    _arguments -C \
        '-h[display help message]' \
        ':remote:__gitex_branch_names'
}

_git-update-all() {
    _arguments -C \
        '-h[display help message]' \
        ':remote:__gitex_branch_names'
}

zstyle -g existing_user_commands ':completion:*:*:git:*' user-commands

zstyle ':completion:*:*:git:*' user-commands "${existing_user_commands}" \
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
    fixup-with:'Interactively lets you pick a commit from a list to fixup' \
    fixup:'amend all local staged changes into the last commit' \
    has-local-changes:'helper function that determines whether there are local changes' \
    has-local-commits:'tests local commits still have to be pushed to origin' \
    initial-commit:'prints the initial commit for the repo' \
    is-ancestor:'tests if first is an ancestor of second' \
    is-clean:'helper function that determines whether there are local changes' \
    is-dirty:'helper function that determines whether there are local changes' \
    is-headless:'tests if HEAD is pointing to a branch head' \
    is-repo:'checks if the current directory is a Git repo' \
    last-commit-to-file:'Returns the SHA of the commit that last touched the given file' \
    local-branch-exists:'tests if the given local branch exists' \
    local-branches:'returns a list of local branches in machine-processable style' \
    local-commits:'returns a list of commits that are still in your local repo, but haven'\''t been pushed to origin' \
    main-branch:'returns the name of the default main branch' \
    merge-status:'shows merge status of all local branches against branch (defaults to the main branch)' \
    merged:'shows what local branches have been merged into branch (defaults to master)' \
    merges-cleanly:'Performes a temporal merge against the given branch and reports success or failure through the exit code.' \
    modified-since:'like git-modified, but for printing a list of files that have been modified since master' \
    modified:'Prints list of files that are locally modified (and exist)' \
    push-current:'pushed the current branch to origin, and makes sure to setup tracking of the remote branch' \
    recent-branches:'Shows a list of local branches, ordered by their date' \
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
    workon:'convenience command for quickly switching to a branch' 

#!/bin/bash

# Print a separator line
print_separator() {
    echo "========================================================"
}

# Print a sub-separator line
print_sub_separator() {
    echo "--------------------------------------------------------"
}

# Check if a directory is a Git project
is_git_project() {
    local dir=$1
    [ -d "$dir/.git" ]
}

# Get the current branch name
get_current_branch() {
    git branch | grep '^\*' | cut -d' ' -f2
}

# Get the remote URL of the repository
get_remote_url() {
    git remote get-url origin
}

# Process a Git project
process_git_project() {
    local dir=$1
    cd "$dir" || return

    # Print a separator line
    print_separator

    # Print the repository URL
    echo "Repository: $(get_remote_url)"

    # Get and print the current branch
    local current_branch
    current_branch=$(get_current_branch)
    echo "Current branch: $current_branch"

    # Check if the current branch is master
    local is_master=false
    if [ "$current_branch" == "master" ]; then
        is_master=true
    fi

    # Check if a stash operation is needed
    local did_stashed=false
    local stash_count_1 stash_count_2
    stash_count_1=$(git stash list | wc -l)

    print_sub_separator
    echo "* git stash"
    echo
    git add .
    git stash
    stash_count_2=$(git stash list | wc -l)
    if [ "$stash_count_1" != "$stash_count_2" ]; then
        did_stashed=true
    fi
    echo

    # If not on master, switch to master
    if ! $is_master; then
        print_sub_separator
        echo "* checkout master branch"
        echo
        git checkout master
        echo
    fi

    # Pull the latest changes
    print_sub_separator
    echo "* git pull"
    echo
    git pull
    echo

    # Prune remote branches
    print_sub_separator
    echo "* prune remote branch"
    echo
    git remote prune origin
    echo

    # If not on master, switch back to the original branch
    if ! $is_master; then
        print_sub_separator
        echo "* recover $current_branch"
        echo
        git checkout "$current_branch"
        echo
    fi

    # If stashed, pop the stash
    if $did_stashed; then
        print_sub_separator
        echo "* recover commits"
        echo
        git stash pop
        git reset
        echo
    fi

    print_separator
    echo

    cd ..
}

# Main function
main() {
    local dest_path=${1:-"."}  # Target path, default is the current directory
    local root_path

    # Get the absolute path
    root_path=$(cd "$dest_path" && pwd)
    cd "$root_path" || exit

    # Iterate through directories
    for dir in $(ls "$root_path"); do
        if [ -f "$dir" ]; then
            echo "$dir is a file"
            continue
        fi

        if ! is_git_project "$dir"; then
            echo "$dir is not a git project"
            continue
        fi

        process_git_project "$dir"
    done
}

## Execute the main function
main "$@"

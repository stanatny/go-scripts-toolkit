#!/bin/bash

# ANSI color codes
COLOR_RESET="\033[0m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_MAGENTA="\033[35m"
COLOR_CYAN="\033[36m"

# Print a separator line
print_separator() {
    echo "${COLOR_BLUE}========================================================${COLOR_RESET}"
}

# Print a sub-separator line
print_sub_separator() {
    echo "${COLOR_CYAN}--------------------------------------------------------${COLOR_RESET}"
}

# Check if a directory is a Git project
is_git_project() {
    local dir=$1
    [ -d "$dir/.git" ]
}

# Get the current branch name
get_current_branch() {
    git branch 2>/dev/null | grep '^\*' | cut -d' ' -f2
}

# Get the remote URL of the repository
get_remote_url() {
    git remote get-url origin 2>/dev/null
}

# Global variables to store processed directories and Git repositories
processed_dirs=()
git_repos=()

# Process a Git project
process_git_project() {
    local dir=$1
    cd "$dir" || return

    # Add the Git repository to the list
    git_repos+=("$dir")

    # Print a separator line
    print_separator
    echo "${COLOR_GREEN}Processing Git repository: ${COLOR_YELLOW}$dir${COLOR_RESET}"

    # Print the repository URL
    local remote_url
    remote_url=$(get_remote_url)
    echo "${COLOR_CYAN}Repository: ${COLOR_MAGENTA}${remote_url:-'No remote URL found'}${COLOR_RESET}"
    echo

    # Get and print the current branch
    local current_branch
    current_branch=$(get_current_branch)
    echo "${COLOR_CYAN}Current branch: ${COLOR_MAGENTA}${current_branch:-'No branch found'}${COLOR_RESET}"
    echo

    # Check if the current branch is master
    local is_master=false
    if [ "$current_branch" == "master" ]; then
        is_master=true
    fi

    # Check if stash is needed
    local did_stashed=false
    print_sub_separator
    echo "${COLOR_CYAN}* Checking for uncommitted changes${COLOR_RESET}"
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "${COLOR_YELLOW}Uncommitted changes detected. Stashing changes...${COLOR_RESET}"
        git add . >/dev/null 2>&1
        git stash
        did_stashed=true
    else
        echo "${COLOR_GREEN}No uncommitted changes detected. Skipping stash.${COLOR_RESET}"
    fi
    echo

    # If not on master, switch to master
    if ! $is_master; then
        print_sub_separator
        echo "${COLOR_CYAN}* Switching to master branch${COLOR_RESET}"
        git checkout master || echo "${COLOR_RED}Failed to checkout master${COLOR_RESET}"
        echo
    fi

    # Pull the latest changes
    print_sub_separator
    echo "${COLOR_CYAN}* Pulling latest changes${COLOR_RESET}"
    git pull || echo "${COLOR_RED}Failed to pull latest changes${COLOR_RESET}"
    echo

    # Prune remote branches
    print_sub_separator
    echo "${COLOR_CYAN}* Pruning remote branches${COLOR_RESET}"
    git remote prune origin
    echo

    # If not on master, switch back to the original branch
    if ! $is_master; then
        print_sub_separator
        echo "${COLOR_CYAN}* Switching back to branch: ${COLOR_MAGENTA}$current_branch${COLOR_RESET}"
        git checkout "$current_branch" || echo "${COLOR_RED}Failed to checkout $current_branch${COLOR_RESET}"
        echo
    fi

    # If stashed, pop the stash
    if $did_stashed; then
        print_sub_separator
        echo "${COLOR_CYAN}* Restoring stashed changes${COLOR_RESET}"
        git stash pop
        echo
    fi

    print_separator
    echo
    cd ..
}

# Recursive function to process directories
process_directory() {
    local dir=$1

    # Add the directory to the processed list
    processed_dirs+=("$dir")

    echo "${COLOR_GREEN}Entering directory: ${COLOR_YELLOW}$dir${COLOR_RESET}"

    for item in "$dir"/*; do
        if [ -f "$item" ]; then
            # Skip files silently
            continue
        elif [ -d "$item" ]; then
            if is_git_project "$item"; then
                process_git_project "$item"
            else
                echo "${COLOR_CYAN}Recursing into non-Git directory: ${COLOR_YELLOW}$item${COLOR_RESET}"
                process_directory "$item"
            fi
        fi
    done
}

# Print summary information
print_summary() {
    echo
    print_separator
    echo "${COLOR_GREEN}Summary:${COLOR_RESET}"
    echo "${COLOR_CYAN}Processed directories:${COLOR_RESET}"
    for dir in "${processed_dirs[@]}"; do
        echo "  - ${COLOR_YELLOW}$dir${COLOR_RESET}"
    done
    echo
    echo "${COLOR_CYAN}Git repositories processed:${COLOR_RESET}"
    for repo in "${git_repos[@]}"; do
        echo "  - ${COLOR_YELLOW}$repo${COLOR_RESET}"
    done
    print_separator
}

# Main function
main() {
    local dest_path=${1:-"."}  # Target path, default is the current directory
    local root_path

    root_path=$(cd "$dest_path" && pwd)
    cd "$root_path" || exit

    echo "${COLOR_GREEN}Starting processing from: ${COLOR_YELLOW}$root_path${COLOR_RESET}"
    process_directory "$root_path"

    # Print summary
    print_summary
}

## Execute the main function
main "$@"

#!/bin/bash

# ANSI color codes
COLOR_RESET="\033[0m"

COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_MAGENTA="\033[35m"
COLOR_CYAN="\033[36m"

BG_COLOR_RED="\033[41m"
BG_COLOR_GREEN="\033[42m"
BG_COLOR_YELLOW="\033[43m"
BG_COLOR_BLUE="\033[44m"
BG_COLOR_MAGENTA="\033[45m"
BG_COLOR_CYAN="\033[46m"
BG_COLOR_WHITE="\033[47m"
BG_COLOR_BLACK="\033[40m"
BG_COLOR_ORANGE="\033[48;5;202m"
BG_COLOR_PURPLE="\033[48;5;93m"
BG_COLOR_TEAL="\033[48;5;30m"
BG_COLOR_PINK="\033[48;5;213m"
BG_COLOR_BROWN="\033[48;5;94m"

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

# Record the start time of the script
start_time=$(date +%s)

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
                cur_item=$item
                echo "${BG_COLOR_BROWN}${COLOR_CYAN}Recursing into non-Git directory: ${COLOR_YELLOW}$cur_item${COLOR_RESET}"
                process_directory "$cur_item"
                echo "${BG_COLOR_BROWN}${COLOR_CYAN}Recursion completed successfully for non-Git directory: ${COLOR_YELLOW}$cur_item${COLOR_RESET}"
                echo
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

    # Calculate and print script execution time
    end_time=$(date +%s)
    execution_time=$((end_time - start_time))
    echo
    echo "${COLOR_CYAN}Script execution time: ${COLOR_MAGENTA}${execution_time} seconds${COLOR_RESET}"

    print_separator
}

# Main function
main() {
    # Check if a path is provided as an argument
    local dest_path=${1:-"."}  # Default to current directory if no path is provided

    # Validate the provided path
    if [ ! -d "$dest_path" ]; then
        echo "${COLOR_RED}Error: The provided path '$dest_path' is not a valid directory.${COLOR_RESET}"
        exit 1
    fi

    # Get the absolute path of the target directory
    local root_path
    root_path=$(cd "$dest_path" && pwd) || {
        echo "${COLOR_RED}Error: Failed to resolve the absolute path of '$dest_path'.${COLOR_RESET}"
        exit 1
    }

    # Start processing from the target directory
    echo "${COLOR_GREEN}Starting processing from: ${COLOR_YELLOW}$root_path${COLOR_RESET}"
    process_directory "$root_path"

    # Print summary
    print_summary
}

## Execute the main function
main "$@"

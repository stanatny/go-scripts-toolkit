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

# Configuration options
LOG_FILE="git_pull_$(date +%Y%m%d_%H%M%S).log"
ENABLE_LOGGING=false  # Set to true to enable logging
PARALLEL_JOBS=4       # Maximum number of parallel jobs

# Logging function
log_message() {
    local message=$1
    echo "$message"
    if [ "$ENABLE_LOGGING" = true ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
    fi
}

# Print a separator line
print_separator() {
    log_message "${COLOR_BLUE}========================================================${COLOR_RESET}"
}

# Print a sub-separator line
print_sub_separator() {
    log_message "${COLOR_CYAN}--------------------------------------------------------${COLOR_RESET}"
}

# Check Git version
check_git_version() {
    local git_version
    git_version=$(git --version | awk '{print $3}')
    log_message "${COLOR_CYAN}Git version: ${COLOR_MAGENTA}$git_version${COLOR_RESET}"
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
failed_repos=()

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
    log_message "${COLOR_GREEN}Processing Git repository: ${COLOR_YELLOW}$dir${COLOR_RESET}"
    
    # Print the repository URL
    local remote_url
    remote_url=$(get_remote_url)
    log_message "${COLOR_CYAN}Repository: ${COLOR_MAGENTA}${remote_url:-'No remote URL found'}${COLOR_RESET}"
    echo
    
    # Get and print the current branch
    local current_branch
    current_branch=$(get_current_branch)
    log_message "${COLOR_CYAN}Current branch: ${COLOR_MAGENTA}${current_branch:-'No branch found'}${COLOR_RESET}"
    echo
    
    # Determine the default branch (master/main)
    local default_branch
    default_branch=$(git remote show origin 2>/dev/null | grep "HEAD branch" | awk '{print $NF}')
    if [ -z "$default_branch" ]; then
        log_message "${COLOR_YELLOW}Unable to determine default branch. Assuming 'master'.${COLOR_RESET}"
        default_branch="master"
    fi
    
    # Check if the current branch is the default branch
    local is_default_branch=false
    if [ "$current_branch" == "$default_branch" ]; then
        is_default_branch=true
    fi
    
    # Check if stash is needed
    local did_stashed=false
    print_sub_separator
    log_message "${COLOR_CYAN}* Checking for uncommitted changes${COLOR_RESET}"
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_message "${COLOR_YELLOW}Uncommitted changes detected. Stashing changes...${COLOR_RESET}"
        git add . >/dev/null 2>&1
        git stash
        did_stashed=true
    else
        log_message "${COLOR_GREEN}No uncommitted changes detected. Skipping stash.${COLOR_RESET}"
    fi
    echo
    
    # If not on the default branch, switch to it
    if ! $is_default_branch; then
        print_sub_separator
        log_message "${COLOR_CYAN}* Switching to default branch: ${COLOR_MAGENTA}$default_branch${COLOR_RESET}"
        if ! git checkout $default_branch; then
            log_message "${COLOR_RED}Failed to checkout $default_branch${COLOR_RESET}"
            failed_repos+=("$dir")
            cd ..
            return 1
        fi
        echo
    fi
    
    # Pull the latest changes
    print_sub_separator
    log_message "${COLOR_CYAN}* Pulling latest changes${COLOR_RESET}"
    if ! git pull --rebase; then
        log_message "${COLOR_RED}Failed to pull latest changes${COLOR_RESET}"
        failed_repos+=("$dir")
    fi
    echo
    
    # Prune remote branches
    print_sub_separator
    log_message "${COLOR_CYAN}* Pruning remote branches${COLOR_RESET}"
    git remote prune origin
    echo
    
    # If not on the default branch, switch back to the original branch
    if ! $is_default_branch; then
        print_sub_separator
        log_message "${COLOR_CYAN}* Switching back to branch: ${COLOR_MAGENTA}$current_branch${COLOR_RESET}"
        if ! git checkout $current_branch; then
            log_message "${COLOR_RED}Failed to checkout $current_branch${COLOR_RESET}"
            failed_repos+=("$dir")
        fi
        echo
    fi
    
    # If stashed, pop the stash
    if $did_stashed; then
        print_sub_separator
        log_message "${COLOR_CYAN}* Restoring stashed changes${COLOR_RESET}"
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
    
    log_message "${COLOR_GREEN}Entering directory: ${COLOR_YELLOW}$dir${COLOR_RESET}"
    
    # Collect all Git projects
    local git_projects=()
    for item in "$dir"/*; do
        if [ -d "$item" ]; then
            if is_git_project "$item"; then
                git_projects+=("$item")
            else
                cur_item=$item
                log_message "${BG_COLOR_BROWN}${COLOR_CYAN}Recursing into non-Git directory: ${COLOR_YELLOW}$cur_item${COLOR_RESET}"
                process_directory "$cur_item"
                log_message "${BG_COLOR_BROWN}${COLOR_CYAN}Recursion completed successfully for non-Git directory: ${COLOR_YELLOW}$cur_item${COLOR_RESET}"
                echo
            fi
        fi
    done
    
    # If parallel processing is supported and there are multiple Git projects, process them in parallel
    if command -v parallel >/dev/null 2>&1 && [ ${#git_projects[@]} -gt 1 ]; then
        log_message "${COLOR_CYAN}Processing ${#git_projects[@]} Git projects in parallel...${COLOR_RESET}"
        export -f process_git_project is_git_project get_current_branch get_remote_url print_separator print_sub_separator log_message
        export COLOR_RESET COLOR_RED COLOR_GREEN COLOR_YELLOW COLOR_BLUE COLOR_MAGENTA COLOR_CYAN BG_COLOR_BROWN
        printf "%s\n" "${git_projects[@]}" | parallel -j $PARALLEL_JOBS process_git_project
    else
        # Process Git projects sequentially
        for project in "${git_projects[@]}"; do
            process_git_project "$project"
        done
    fi
}

# Print summary information
print_summary() {
    echo
    print_separator
    log_message "${COLOR_GREEN}Summary:${COLOR_RESET}"
    log_message "${COLOR_CYAN}Processed directories:${COLOR_RESET}"
    for dir in "${processed_dirs[@]}"; do
        log_message "  - ${COLOR_YELLOW}$dir${COLOR_RESET}"
    done
    echo
    log_message "${COLOR_CYAN}Git repositories processed:${COLOR_RESET}"
    for repo in "${git_repos[@]}"; do
        log_message "  - ${COLOR_YELLOW}$repo${COLOR_RESET}"
    done
    
    # Print failed repositories
    if [ ${#failed_repos[@]} -gt 0 ]; then
        echo
        log_message "${COLOR_RED}Failed Git repositories:${COLOR_RESET}"
        for repo in "${failed_repos[@]}"; do
            log_message "  - ${COLOR_YELLOW}$repo${COLOR_RESET}"
        done
    fi
    
    # Calculate and print script execution time
    end_time=$(date +%s)
    execution_time=$((end_time - start_time))
    echo
    log_message "${COLOR_CYAN}Script execution time: ${COLOR_MAGENTA}${execution_time} seconds${COLOR_RESET}"
    
    print_separator
}

# Main function
main() {
    # Check if a path is provided as an argument
    local dest_path=${1:-.}  # Default to current directory if no path is provided
    
    # Check if Git is installed
    if ! command -v git >/dev/null 2>&1; then
        log_message "${COLOR_RED}Error: Git is not installed. Please install Git and try again.${COLOR_RESET}"
        exit 1
    fi
    
    # Check if GNU Parallel is installed (optional)
    if ! command -v parallel >/dev/null 2>&1; then
        log_message "${COLOR_YELLOW}Warning: GNU Parallel is not installed. Sequential processing will be used.${COLOR_RESET}"
        log_message "To install GNU Parallel:"
        log_message "  - On Ubuntu/Debian: sudo apt-get install parallel"
        log_message "  - On macOS: brew install parallel"
        log_message "  - On Windows: Use WSL or install via Cygwin/MSYS2"
    fi
    
    # Check Git version
    check_git_version
    
    # Validate the provided path
    if [ ! -d "$dest_path" ]; then
        log_message "${COLOR_RED}Error: The provided path '$dest_path' is not a valid directory.${COLOR_RESET}"
        exit 1
    fi
    
    # Get the absolute path of the target directory
    local root_path
    root_path=$(cd "$dest_path" && pwd) || {
        log_message "${COLOR_RED}Error: Failed to resolve the absolute path of '$dest_path'.${COLOR_RESET}"
        exit 1
    }
    
    # Start processing from the target directory
    log_message "${COLOR_GREEN}Starting processing from: ${COLOR_YELLOW}$root_path${COLOR_RESET}"
    process_directory "$root_path"
    
    # Print summary
    print_summary
}

## Execute the main function
main "$@"

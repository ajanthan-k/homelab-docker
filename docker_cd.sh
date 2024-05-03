#!/bin/bash

BASE_DIR="/docker"              # Set the base directory to /docker
LOG_FILE="/tmp/dccd.log"        # Default log file name
REMOTE_BRANCH="main"            # Default remote branch name

log_message() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

update_compose_files() {
    cd "$BASE_DIR" || { log_message "ERROR: Directory doesn't exist, exiting..."; exit 127; }

    # Make sure we're in a git repo
    if [ ! -d .git ]; then
        log_message "ERROR: Directory is not a git repository, exiting..."
        exit 1
    else
        log_message "INFO:  Git repository found!"
    fi

    # Check if there are any changes in the Git repository
    if ! git fetch origin; then
        log_message "ERROR: Unable to fetch changes from the remote repository (the server may be offline or unreachable)"
        exit 1
    fi

    # Check for uncommitted local changes
    uncommitted_changes=$(git status --porcelain)
    if [ -n "$uncommitted_changes" ]; then
        log_message "ERROR: Uncommitted changes detected in $BASE_DIR, exiting..."
        exit 1
    fi

    # Get the list of changed files
    changed_files=$(git diff --name-only HEAD origin/$REMOTE_BRANCH)

    if [ -n "$changed_files" ]; then
        log_message "STATE: Changes detected, updating..."

        # Pull the changes from the remote repository
        if ! git pull --quiet origin "$REMOTE_BRANCH"; then
            log_message "ERROR: Unable to pull changes from the remote repository (the server may be offline or unreachable)"
            exit 1
        fi

        # Iterate over the changed files
        while IFS= read -r file; do
            # Check if the file is a Docker Compose file
            if [[ "$file" == *"docker-compose.yml" || "$file" == *"docker-compose.yaml" ]]; then
                log_message "STATE: Redeploying compose file for $file"
                docker compose -f "$file" up -d --quiet-pull
            fi
        done <<< "$changed_files"
    else
        log_message "STATE: No changes detected, nothing to do"
    fi

    # Check if PRUNE is provided
    if [ $PRUNE -eq 1 ]; then
        log_message "STATE: Pruning images"
        docker image prune --all --force
    fi

    log_message "STATE: Done!"
}

touch "$LOG_FILE"
{
  echo "########################################"
  echo "# Starting!"
  echo "########################################"
} >> "$LOG_FILE"

log_message "INFO:  Base directory is set to $BASE_DIR"

update_compose_files

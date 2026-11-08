#!/bin/bash
# Pulls /docker from GitHub and redeploys any stack whose compose file changed.

# Wrapped in { } so bash reads the whole script before running it,
# since the git merge below may update this file.
{
    LOG_FILE=/tmp/dccd.log
    STATE_FILE=.git/dccd-deployed   # last commit that was deployed

    log() {
        echo "$(date '+%F %T') - $*" | tee -a "$LOG_FILE"
    }

    cd /docker || exit 1

    # 1. Update the repo. Git refuses if a file edited locally also changed upstream.
    if ! git fetch -q origin; then
        log "ERROR: fetch failed"
        exit 1
    fi

    if ! git merge -q --ff-only origin/main; then
        log "ERROR: fast-forward failed, see git status"
        exit 1
    fi

    # 2. Work out what changed since the last deploy.
    current=$(git rev-parse HEAD)
    last_deployed=$(cat "$STATE_FILE" 2>/dev/null)

    if ! git cat-file -e "$last_deployed^{commit}" 2>/dev/null; then
        last_deployed=$current
    fi

    changed_files=$(git diff --name-only --diff-filter=d "$last_deployed" "$current" \
        -- '*docker-compose.yml' '*docker-compose.yaml')

    # 3. Redeploy changed stacks. Only record the deploy if all succeeded,
    #    so failures are retried next run.
    all_ok=true

    for file in $changed_files; do
        log "Redeploying $file"

        if ! docker compose -f "$file" up -d --quiet-pull; then
            log "ERROR: redeploy failed for $file"
            all_ok=false
        fi
    done

    if $all_ok; then
        echo "$current" > "$STATE_FILE"
    fi

    $all_ok
    exit
}

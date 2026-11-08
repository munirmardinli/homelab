#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=src/cli/log.sh
source "$REPO_ROOT/src/cli/log.sh"

run_pull() {
    local local_changes=0
    cd "$REPO_ROOT"
    echo "======== started $(date '+%Y-%m-%d %H:%M:%S') ========"
    echo "Repository: $REPO_ROOT"
    if [[ -n "$(git status --porcelain)" ]]; then
        local_changes=1
        echo "Local changes detected; preserving them and skipping cleanup, commit, and push."
    else
        echo "Cleaning @eaDir directories..."
        find . -name "@eaDir" -type d -exec rm -rf {} + 2>/dev/null || true

        echo "Cleaning .DS_Store files..."
        find . -name ".DS_Store" -type f -delete 2>/dev/null || true

        echo "Staging changes..."
        git add .

        if ! git diff-index --quiet HEAD --; then
            echo "Committing updates..."
            git commit -m "update"
        fi
    fi

    echo "Pulling latest changes (rebase with autostash)..."
    if ! git pull --rebase --autostash origin main; then
        echo "Conflict detected during pull. Please resolve manually."
        return 1
    fi

    if ((local_changes)); then
        echo "Pull complete. Local changes were restored; push skipped."
        setup_log_journal "pull complete local_changes=preserved push=skipped"
    else
        echo "Pushing to remote..."
        git push origin main
    fi

    echo "Sync complete!"
}

case "${1:-run}" in
    run)
        run_pull
        ;;
    --install-schedule)
        exec /bin/bash "$REPO_ROOT/src/settings/pullSchedule.sh" install
        ;;
    --remove-schedule)
        exec /bin/bash "$REPO_ROOT/src/settings/pullSchedule.sh" remove
        ;;
    --status-schedule)
        exec /bin/bash "$REPO_ROOT/src/settings/pullSchedule.sh" status
        ;;
    --run)
        run_pull
        ;;
    *)
        echo "Usage: $0 [run|--install-schedule|--remove-schedule]" >&2
        exit 2
        ;;
esac

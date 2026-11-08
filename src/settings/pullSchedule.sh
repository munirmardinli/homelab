#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
AGENT_LABEL="dev.mardinli.mac.repo-pull"
AGENT_PLIST="$HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"
# shellcheck disable=SC1091
source "$REPO_ROOT/src/cli/log.sh"

run_pull() {
    exec /bin/bash "$REPO_ROOT/pull.sh" run
}

install_schedule() {
    local bash_bin
    bash_bin="$(command -v bash)"
    mkdir -p "$HOME/Library/LaunchAgents" "$REPO_ROOT/assets/logs/cli"

    cat >"$AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${AGENT_LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${bash_bin}</string>
    <string>${SCRIPT_DIR}/pullSchedule.sh</string>
    <string>run</string>
  </array>
  <key>WorkingDirectory</key>
  <string>${REPO_ROOT}</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>${HOME}</string>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>StartInterval</key>
  <integer>1800</integer>
  <key>RunAtLoad</key>
  <false/>
  <key>StandardOutPath</key>
    <string>${REPO_ROOT}/assets/logs/cli/pull-launchd.log</string>
  <key>StandardErrorPath</key>
    <string>${REPO_ROOT}/assets/logs/cli/pull-launchd.log</string>
</dict>
</plist>
EOF

    plutil -lint "$AGENT_PLIST"
    launchctl bootout "gui/$(id -u)/${AGENT_LABEL}" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$AGENT_PLIST"
    setup_log_journal "pull schedule installed interval=1800 label=${AGENT_LABEL}"
    echo "Pull schedule installed: every 30 minutes"
    echo "LaunchAgent: $AGENT_PLIST"
    echo "Run logs: $REPO_ROOT/assets/logs/cli/YYYY-MM-DD/*_pull.log"
}

remove_schedule() {
    launchctl bootout "gui/$(id -u)/${AGENT_LABEL}" 2>/dev/null || true
    rm -f "$AGENT_PLIST"
    setup_log_journal "pull schedule removed label=${AGENT_LABEL}"
    echo "Pull schedule removed."
}

show_status() {
    if launchctl print "gui/$(id -u)/${AGENT_LABEL}" >/dev/null 2>&1; then
        echo "Pull schedule is loaded (every 30 minutes)."
        setup_log_journal "pull schedule status=loaded label=${AGENT_LABEL}"
    else
        echo "Pull schedule is not loaded."
        setup_log_journal "pull schedule status=not-loaded label=${AGENT_LABEL}"
    fi
}

case "${1:-status}" in
    run)
        run_pull
        ;;
    install)
        install_schedule
        ;;
    remove)
        remove_schedule
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 [run|install|remove|status]" >&2
        exit 2
        ;;
esac

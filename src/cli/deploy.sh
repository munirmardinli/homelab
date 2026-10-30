#!/usr/bin/env bash

set -euo pipefail

CLI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -n "${BWS_ACCESS_TOKEN:-}" ]]; then
  export BWS_ACCESS_TOKEN
fi

bash "$CLI_DIR/bitwarden.sh"
bash "$CLI_DIR/generate.sh"
bash "$CLI_DIR/ssh.sh"
bash "$CLI_DIR/compose.sh"
bash "$CLI_DIR/generateSSH.sh"

#!/usr/bin/env bash

setup_log_journal() {
  local root="${SETUP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
  local log_dir="$root/assets/logs/cli"
  mkdir -p "$log_dir"
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$*" >>"$log_dir/setup-journal.log"
}

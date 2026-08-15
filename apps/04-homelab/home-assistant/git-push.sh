#!/usr/bin/env bash

set -euo pipefail

export HOME=/tmp

function log_json() {
  local level="${1:-INFO}"
  local message="${2:-}"
  local timestamp

  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  echo "{\"timestamp\": \"$timestamp\", \"level\": \"$level\", \"message\": \"$message\"}"
}

cd /config

remote=$(git rev-parse --abbrev-ref origin/HEAD)

git fetch origin
git rebase "$remote"

git add .

git commit --message "Autocommit from HA [$(cat .HA_VERSION)]: $(date -u +'%&-%m-%dT%H:%M:%SZ')"

git push --set-upstream

log_json "INFO" "Completed git push of latest config"

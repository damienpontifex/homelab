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

if [[ ! -f "/config/configuration.yaml" ]]; then
  log_json "INFO" "No configuration found. Cloning from gh:damienpontifex/homeassistant-config"
  git clone https://github.com/damienpontifex/homeassistant-config /config
fi

cd /config

git config --global --add safe.directory /config

remote=$(git rev-parse --abbrev-ref origin/HEAD)

git fetch origin

git rebase "$remote"

#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)

while IFS= read -r file; do
  dir=$(dirname "$file")
  kubectl kustomize --enable-helm "$dir" >/dev/null
done < <(find "${repo_root}" -type f -name kustomization.yaml -or -name kustomization.yml)

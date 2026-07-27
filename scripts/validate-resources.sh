#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)

manifest_out=$(mktemp -d)

while IFS= read -r file; do
  dir=$(dirname "$file")
  app_filename=$(basename "$dir")
  >&2 echo "Rendering $app_filename to $manifest_out/$app_filename.yaml"
  kubectl kustomize --enable-helm "$dir" >"$manifest_out/$app_filename.yaml"
done < <(find "${repo_root}" -type f -name kustomization.yaml -or -name kustomization.yml)

crd_out=$(mktemp -d)

for manifest in "$manifest_out"/*.yaml; do
  crd_filename=$(basename "$manifest")
  >&2 echo "Extract CRDs from $manifest"
  yq 'select(.kind == "CustomResourceDefinition")' "$manifest" >"$crd_out/$crd_filename.yaml"
done

kubectl validate --local-crds "$crd_out" "$manifest_out"

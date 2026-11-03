#!/usr/bin/env bash
# Applies the Argo CD and Kargo resources for the POC to the current kubectl context.
# The Git credentials stay out of the repo: set GITHUB_USERNAME and GITHUB_TOKEN before you run it.

set -euo pipefail

: "${GITHUB_USERNAME:?Set GITHUB_USERNAME to the owner of the fork}"
: "${GITHUB_TOKEN:?Set GITHUB_TOKEN to a fine-grained PAT with write access to the fork only}"

repo_url="https://github.com/${GITHUB_USERNAME}/kargo-demo"
dir="$(cd "$(dirname "$0")" && pwd)"

kubectl apply -f "$dir/argocd/applicationset.yaml"

kubectl apply -f "$dir/kargo/project.yaml"
kubectl wait --for=create namespace/kargo-demo --timeout=60s

kubectl create secret generic kargo-demo-repo \
  --namespace kargo-demo \
  --from-literal=repoURL="$repo_url" \
  --from-literal=username="$GITHUB_USERNAME" \
  --from-literal=password="$GITHUB_TOKEN" \
  --dry-run=client -o yaml \
  | kubectl label --local -f - kargo.akuity.io/cred-type=git -o yaml \
  | kubectl apply -f -

kubectl apply -f "$dir/kargo/warehouse.yaml"
kubectl apply -f "$dir/kargo/promotion-task.yaml"
kubectl apply -f "$dir/kargo/stages.yaml"

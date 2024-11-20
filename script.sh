#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://releases.rancher.com/server-charts/latest"
INDEX_FILE="index.yaml"
RELEASE_FOLDER="public"
MIN_VERSION_TO_PATCH="2.9"
SKIP_RC_VERSIONS="false"

mkdir -p tmp
mkdir -p "${RELEASE_FOLDER}"

# Download the index file
curl -s -o "tmp/${INDEX_FILE}" "${REPO_URL}/${INDEX_FILE}"

# Get charts versions
mapfile -t CHART_VERSIONS < <(yq '.entries.rancher[].version' < "tmp/${INDEX_FILE}")

INDEX_UPDATE_CONDITIONS=""

for version in "${CHART_VERSIONS[@]}"; do
  # Only patch versions above min version variable
  if [[ "${version}" < "${MIN_VERSION_TO_PATCH}" ]]; then
    continue
  fi

  # Skip RC versions
  if [[ "${SKIP_RC_VERSIONS}" == "true" && "${version}" == *"rc"* ]]; then
    continue
  fi

  echo "Processing version: ${version}"

  # Download the chart
  curl -s -o "tmp/rancher-${version}.tgz" "${REPO_URL}/rancher-${version}.tgz"

  # Extract the chart
  tar -xzf "tmp/rancher-${version}.tgz" -C tmp

  # Update the chart
  yq -i 'del(.kubeVersion)' tmp/rancher/Chart.yaml

  # Package the chart
  tar -czf "tmp/rancher-${version}.tgz" -C tmp rancher

  # Move to release folder
  mv "tmp/rancher-${version}.tgz" "${RELEASE_FOLDER}/rancher-${version}.tgz"

  # Update the index file
  yq -i '(.entries.rancher[] | select(.version == "'"${version}"'")).digest = "'"$(sha256sum "${RELEASE_FOLDER}/rancher-${version}.tgz" | cut -d' ' -f1)"'"' "tmp/${INDEX_FILE}"
  yq -i 'del((.entries.rancher[] | select(.version == "'"${version}"'")).kubeVersion)' "tmp/${INDEX_FILE}"

  INDEX_UPDATE_CONDITIONS+='.version != "'"${version}"'" and '

  # Cleanup chart folder
  rm -rf tmp/rancher
done

# Update the index file
yq -i '.generated = "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"' "tmp/${INDEX_FILE}"

# Remove unpatched versions from index
yq -i 'del(.entries.rancher.[] | select('"${INDEX_UPDATE_CONDITIONS%and }"'))' "tmp/${INDEX_FILE}"

# Move to release folder
mv "tmp/${INDEX_FILE}" "${RELEASE_FOLDER}/${INDEX_FILE}"

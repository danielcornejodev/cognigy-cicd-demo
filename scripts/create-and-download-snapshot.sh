#!/bin/bash
set -e

echo "==> Installing Cognigy CLI..."
npm install -g @cognigy/cognigy-cli

echo "==> Creating working directories..."
mkdir -p ./snapshots/agent/snapshots

echo "==> Writing CLI config.json for Dev..."
printf '{"baseUrl":"%s","apiKey":"%s","agent":"%s","agentDir":"./snapshots/agent"}' \
  "$CAI_BASEURL" "$CAI_APIKEY" "$CAI_AGENT" > ./config.json

echo "==> Verifying config.json structure..."
echo "==> apiKey length: $(jq -r '.apiKey' ./config.json | wc -c) chars"
echo "==> baseUrl: $(jq -r '.baseUrl' ./config.json)"
echo "==> JSON valid: $(jq empty ./config.json && echo YES || echo NO)"
echo "==> config.json full path: $(realpath ./config.json)"
echo "==> Current working directory: $(pwd)"

# ── VERSION FROM CHANGELOG ────────────────────────────────────────
echo "==> Reading version from CHANGELOG.md..."

if [ ! -f "./CHANGELOG.md" ]; then
  echo "WARNING: CHANGELOG.md not found — falling back to timestamp"
  SNAPSHOT_NAME="release-$(date +%Y%m%d-%H%M%S)"
else
  # Extract the first version line — format: ## v1.0 - 2026-04-17
  CHANGELOG_VERSION=$(grep -m 1 "^## v" ./CHANGELOG.md | awk '{print $2}')

  if [ -z "$CHANGELOG_VERSION" ]; then
    echo "WARNING: No version found in CHANGELOG.md — falling back to timestamp"
    SNAPSHOT_NAME="release-$(date +%Y%m%d-%H%M%S)"
  else
    # Append timestamp to make each snapshot name unique even on same version
    SNAPSHOT_NAME="${CHANGELOG_VERSION}-$(date +%Y%m%d-%H%M%S)"
    echo "==> Version from CHANGELOG: $CHANGELOG_VERSION"
  fi
fi

echo "==> Snapshot name: $SNAPSHOT_NAME"
# ── END VERSION ───────────────────────────────────────────────────

cognigy create snapshot "$SNAPSHOT_NAME" "Automated CI/CD snapshot" -c ./config.json

echo "==> Checking for downloaded .csnap file..."
SNAPSHOT_FILE=$(find ./snapshots/agent/snapshots -name "*.csnap" | head -1)

if [ -z "$SNAPSHOT_FILE" ]; then
  echo "ERROR: Snapshot file not found. Contents of snapshots dir:"
  find ./snapshots -type f
  exit 1
fi

echo "==> Snapshot downloaded: $SNAPSHOT_FILE"
echo "$SNAPSHOT_FILE" > ./snapshots/snapshot_path.txt
echo "$SNAPSHOT_NAME" > ./snapshots/snapshot_name.txt
echo "==> Done."
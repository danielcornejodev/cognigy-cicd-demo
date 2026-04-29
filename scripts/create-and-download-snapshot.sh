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

# ── DEV SNAPSHOT CLEANUP ─────────────────────────────────────────
echo "==> Checking Dev snapshot count..."
DEV_SNAPSHOTS=$(curl -s -X GET \
  "$CAI_BASEURL/v2.0/snapshots?projectId=$CAI_AGENT&limit=10" \
  -H "X-API-Key: $CAI_APIKEY")

DEV_SNAPSHOT_COUNT=$(echo "$DEV_SNAPSHOTS" | jq '._embedded.snapshots | length')
echo "==> Current Dev snapshot count: $DEV_SNAPSHOT_COUNT"

if [ "$DEV_SNAPSHOT_COUNT" -ge 9 ]; then
  OLDEST_ID=$(echo "$DEV_SNAPSHOTS" | jq -r \
    '._embedded.snapshots | sort_by(.createdAt) | first | .snapshotId')
  OLDEST_NAME=$(echo "$DEV_SNAPSHOTS" | jq -r \
    '._embedded.snapshots | sort_by(.createdAt) | first | .name')
  echo "==> At limit — deleting oldest Dev snapshot: $OLDEST_NAME ($OLDEST_ID)"
  curl -s -X DELETE "$CAI_BASEURL/v2.0/snapshots/$OLDEST_ID" \
    -H "X-API-Key: $CAI_APIKEY"
  echo "==> Oldest Dev snapshot deleted"
else
  echo "==> Dev snapshot count OK — no cleanup needed"
fi
# ── END DEV CLEANUP ──────────────────────────────────────────────

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
#!/bin/bash
set -e

echo "==> Installing Cognigy CLI..."
npm install -g @cognigy/cognigy-cli

echo "==> Creating working directories..."
mkdir -p ./snapshots/agent/snapshots

echo "==> Writing CLI config.json for Dev..."
# Use printf instead of heredoc to avoid whitespace/indentation issues
printf '{"baseUrl":"%s","apiKey":"%s","agent":"%s","agentDir":"./snapshots/agent"}' \
  "$CAI_BASEURL" "$CAI_APIKEY" "$CAI_AGENT" > ./config.json

echo "==> Verifying config.json structure..."
echo "==> apiKey length: $(jq -r '.apiKey' ./config.json | wc -c) chars"
echo "==> baseUrl: $(jq -r '.baseUrl' ./config.json)"
echo "==> agent length: $(jq -r '.agent' ./config.json | wc -c) chars"
echo "==> JSON valid: $(jq empty ./config.json && echo YES || echo NO)"

SNAPSHOT_NAME="release-$(date +%Y%m%d-%H%M%S)"
echo "==> Creating snapshot: $SNAPSHOT_NAME"

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
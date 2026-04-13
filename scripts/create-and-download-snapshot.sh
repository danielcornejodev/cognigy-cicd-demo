#!/bin/bash
set -e

echo "==> Installing Cognigy CLI..."
npm install -g @cognigy/cognigy-cli

echo "==> Creating working directories..."
mkdir -p ./snapshots/agent/snapshots

echo "==> Writing CLI config.json for Dev..."
cat > ./config.json << EOF
{
  "baseUrl": "${CAI_BASEURL}",
  "apiKey": "${CAI_APIKEY}",
  "agent": "${CAI_AGENT}",
  "agentDir": "./snapshots/agent"
}
EOF

echo "==> Config written. Verifying (no secrets shown)..."
echo "baseUrl: ${CAI_BASEURL}"
echo "agent: ${CAI_AGENT}"

SNAPSHOT_NAME="release-$(date +%Y%m%d-%H%M%S)"
echo "==> Creating snapshot: $SNAPSHOT_NAME"

# -y skips the interactive confirmation prompt
cognigy create snapshot "$SNAPSHOT_NAME" "Automated CI/CD snapshot" -y

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
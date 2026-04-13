#!/bin/bash
set -e

echo "==> Installing Cognigy CLI..."
npm install -g @cognigy/cognigy-cli

echo "==> Initializing CLI config for Dev..."
# The CLI reads config from environment variables directly
# CAI_BASEURL, CAI_APIKEY, CAI_AGENT, CAI_AGENTDIR are read automatically

# Set the agent dir to our snapshots working folder
export CAI_AGENTDIR=./snapshots/agent
mkdir -p ./snapshots/agent/snapshots

SNAPSHOT_NAME="release-$(date +%Y%m%d-%H%M%S)"
echo "==> Creating snapshot: $SNAPSHOT_NAME"

# This single command: creates snapshot, waits for prepare-download, downloads .csnap
cognigy create snapshot "$SNAPSHOT_NAME" "Automated CI/CD snapshot" -y

# The CLI saves it to: ./snapshots/agent/snapshots/<name>.csnap
SNAPSHOT_FILE=$(ls ./snapshots/agent/snapshots/*.csnap | head -1)

if [ -z "$SNAPSHOT_FILE" ]; then
  echo "ERROR: Snapshot file not found after CLI create command"
  exit 1
fi

echo "==> Snapshot downloaded: $SNAPSHOT_FILE"

# Save the path for the next script to use
echo "$SNAPSHOT_FILE" > ./snapshots/snapshot_path.txt
echo "$SNAPSHOT_NAME" > ./snapshots/snapshot_name.txt
echo "==> Done. Snapshot path saved to snapshots/snapshot_path.txt"

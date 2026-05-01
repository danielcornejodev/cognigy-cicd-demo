#!/bin/bash
set -e

echo "==> Installing Cognigy CLI..."
npm install -g @cognigy/cognigy-cli

echo "==> Verifying environment variables..."
echo "==> CAI_BASEURL length: $(echo -n $CAI_BASEURL | wc -c) chars"
echo "==> CAI_APIKEY length: $(echo -n $CAI_APIKEY | wc -c) chars"
echo "==> CAI_AGENT length: $(echo -n $CAI_AGENT | wc -c) chars"

echo "==> Verifying playbooks.json..."
cat ./playbooks/playbooks.json
echo "==> Playbook count: $(jq 'length' ./playbooks/playbooks.json)"

echo "==> Running playbooks via environment variables (no config.json)..."
# Export explicitly to ensure child process inherits them
export CAI_BASEURL=$CAI_BASEURL
export CAI_APIKEY=$CAI_APIKEY
export CAI_AGENT=$CAI_AGENT
export CAI_AGENTDIR=.

cognigy run ./playbooks/playbooks.json

echo "==> Checking results..."
if [ ! -f "playbookRunResults.json" ]; then
  echo "ERROR: playbookRunResults.json not found — CLI may have failed silently"
  exit 1
fi

echo "==> Playbook results:"
cat playbookRunResults.json

FAILED=$(cat playbookRunResults.json | jq '[.[] | select(.status != "succeeded")] | length')

if [ "$FAILED" -gt "0" ]; then
  echo "ERROR: $FAILED playbook(s) failed ❌"
  cat playbookRunResults.json | jq '[.[] | {name: .name, status: .status}]'
  exit 1
fi

echo "==> All playbooks passed ✅"
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

# Copy playbooks.json to root working directory — CLI default location
cp ./playbooks/playbooks.json ./playbooks.json

echo "==> Copied playbooks.json to working directory root"
echo "==> Working directory contents:"
ls -la | grep playbooks

export CAI_BASEURL=$CAI_BASEURL
export CAI_APIKEY=$CAI_APIKEY
export CAI_AGENT=$CAI_AGENT
export CAI_AGENTDIR=.

echo "==> Running: cognigy run"
cognigy run

echo "==> Checking results..."
if [ ! -f "playbookRunResults.json" ]; then
  echo "ERROR: playbookRunResults.json not found"
  echo "==> Directory contents after run:"
  ls -la
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
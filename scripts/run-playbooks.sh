#!/bin/bash
set -e

echo "==> Installing Cognigy CLI (if not already installed)..."
npm install -g @cognigy/cognigy-cli

echo "==> Running playbooks against Dev using CLI..."

# CLI reads CAI_BASEURL, CAI_APIKEY, CAI_AGENT from environment
# Playbook definitions come from ./playbooks/playbooks.json

cognigy run --file ./playbooks/playbooks.json

echo "==> Playbook run complete. Results in ./playbookRunResults.json"

# Check if any playbook failed
FAILED=$(cat playbookRunResults.json | jq '[.[] | select(.status != "succeeded")] | length')
if [ "$FAILED" -gt "0" ]; then
  echo "ERROR: $FAILED playbook(s) failed. See playbookRunResults.json"
  exit 1
fi

echo "==> All playbooks passed ✅"

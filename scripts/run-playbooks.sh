#!/bin/bash
set -e

echo "==> Installing Cognigy CLI..."
npm install -g @cognigy/cognigy-cli

echo "==> Writing CLI config.json..."
printf '{"name":"cicd-pipeline","baseUrl":"%s","apiKey":"%s","agent":"%s","agentDir":".","filePath":"./config.json"}' \
  "$CAI_BASEURL" "$CAI_APIKEY" "$CAI_AGENT" > ./config.json

echo "==> Verifying config..."
echo "==> apiKey length: $(jq -r '.apiKey' ./config.json | wc -c) chars"
echo "==> baseUrl: $(jq -r '.baseUrl' ./config.json)"
echo "==> name: $(jq -r '.name' ./config.json)"
echo "==> filePath: $(jq -r '.filePath' ./config.json)"
echo "==> JSON valid: $(jq empty ./config.json && echo YES || echo NO)"

echo "==> Verifying playbooks.json..."
cat ./playbooks/playbooks.json
echo "==> Playbook count: $(jq 'length' ./playbooks/playbooks.json)"

echo "==> Running playbooks..."
cognigy run --file ./playbooks/playbooks.json

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
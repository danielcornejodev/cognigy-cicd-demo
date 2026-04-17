#!/bin/bash
set -e

TARGET_ENV=$1

if [ "$TARGET_ENV" == "qa" ]; then
  TEST_ENDPOINT_URL=$QA_ENDPOINT_URL
elif [ "$TARGET_ENV" == "prod" ]; then
  TEST_ENDPOINT_URL=$PROD_ENDPOINT_URL
else
  echo "ERROR: Use 'qa' or 'prod'"
  exit 1
fi

echo "==> Running smoke test against $TARGET_ENV endpoint..."
echo "==> Sending 'hello' to endpoint..."

RESPONSE=$(curl -s -X POST "$TEST_ENDPOINT_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": \"cicd-smoke-test\",
    \"sessionId\": \"smoke-$(date +%s)\",
    \"text\": \"hello\"
  }")

echo "==> Bot response: $RESPONSE"

# Check response is not empty
if [ -z "$RESPONSE" ]; then
  echo "ERROR: Empty response from endpoint ❌"
  exit 1
fi

# Check for error indicators
if echo "$RESPONSE" | grep -qi "error\|cannot\|invalid\|unauthorized"; then
  echo "ERROR: Response contains error indicators ❌"
  exit 1
fi

# Check for expected content
if echo "$RESPONSE" | grep -q "Hello from"; then
  echo "==> SMOKE TEST PASSED ✅ - Bot responded with expected content"
else
  echo "==> SMOKE TEST FAILED ❌ - Expected 'Hello from' in response"
  echo "==> Full response: $RESPONSE"
  exit 1
fi
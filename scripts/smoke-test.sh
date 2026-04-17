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

MAX_ATTEMPTS=3
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  echo "==> Attempt $ATTEMPT of $MAX_ATTEMPTS..."

  RESPONSE=$(curl -s -X POST "$TEST_ENDPOINT_URL" \
    -H "Content-Type: application/json" \
    -d "{
      \"userId\": \"cicd-smoke-test\",
      \"sessionId\": \"smoke-$(date +%s)\",
      \"text\": \"hello\"
    }")

  echo "==> Bot response: $RESPONSE"

  # Skip retry checks if empty
  if [ -z "$RESPONSE" ]; then
    echo "==> Empty response, retrying..."
    ATTEMPT=$((ATTEMPT + 1))
    sleep 15
    continue
  fi

  # If 502/CloudFront error, retry
  if echo "$RESPONSE" | grep -q "502\|Bad Gateway\|CloudFront"; then
    echo "==> Platform temporarily unavailable (502), retrying in 30 seconds..."
    ATTEMPT=$((ATTEMPT + 1))
    sleep 30
    continue
  fi

  # Check for other errors
  if echo "$RESPONSE" | grep -qi "error\|cannot\|invalid\|unauthorized"; then
    echo "==> SMOKE TEST FAILED ❌ - Error in response"
    exit 1
  fi

  # Check for expected content
  if echo "$RESPONSE" | grep -q "Hello from"; then
    echo "==> SMOKE TEST PASSED ✅ - Bot responded with expected content"
    exit 0
  else
    echo "==> SMOKE TEST FAILED ❌ - Expected 'Hello from' in response"
    echo "==> Full response: $RESPONSE"
    exit 1
  fi
done

echo "==> SMOKE TEST FAILED ❌ - Platform unavailable after $MAX_ATTEMPTS attempts"
exit 1
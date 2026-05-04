#!/bin/bash
set -e

TARGET_ENV=$1

if [ "$TARGET_ENV" == "qa" ]; then
  TEST_ENDPOINT_URL=$QA_ENDPOINT_URL
  RETRY_WAIT=30
elif [ "$TARGET_ENV" == "prod" ]; then
  TEST_ENDPOINT_URL=$PROD_ENDPOINT_URL
  RETRY_WAIT=60
fi

echo "==> Running smoke test against $TARGET_ENV endpoint..."
echo "==> Endpoint URL length: $(echo -n $TEST_ENDPOINT_URL | wc -c) chars"
echo "==> Endpoint URL prefix: $(echo $TEST_ENDPOINT_URL | cut -c1-40)..."

MAX_ATTEMPTS=5
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  echo "==> Attempt $ATTEMPT of $MAX_ATTEMPTS..."

  RESPONSE=$(curl -s --max-time 30 -X POST "$TEST_ENDPOINT_URL" \
    -H "Content-Type: application/json" \
    -d "{
      \"userId\": \"cicd-smoke-test\",
      \"sessionId\": \"smoke-$(date +%s)\",
      \"text\": \"hello\"
    }")

  echo "==> Bot response: $RESPONSE"

  if [ -z "$RESPONSE" ]; then
    echo "==> Empty response, retrying in ${RETRY_WAIT}s..."
    ATTEMPT=$((ATTEMPT + 1))
    sleep $RETRY_WAIT
    continue
  fi

  if echo "$RESPONSE" | grep -q "502\|Bad Gateway\|CloudFront"; then
    echo "==> Platform temporarily unavailable (502), retrying in ${RETRY_WAIT}s..."
    ATTEMPT=$((ATTEMPT + 1))
    sleep $RETRY_WAIT
    continue
  fi

  if echo "$RESPONSE" | grep -qi "error\|cannot\|invalid\|unauthorized"; then
    echo "==> SMOKE TEST FAILED ❌ - Error in response"
    exit 1
  fi

  if echo "$RESPONSE" | jq -e '.outputStack' > /dev/null 2>&1; then
    echo "==> SMOKE TEST PASSED ✅ - Bot responded with valid JSON outputStack"
    exit 0
  else
    echo "==> SMOKE TEST FAILED ❌ - Invalid response format"
    echo "==> Full response: $RESPONSE"
    exit 1
  fi
done

echo "==> SMOKE TEST FAILED ❌ - Platform unavailable after $MAX_ATTEMPTS attempts"
exit 1
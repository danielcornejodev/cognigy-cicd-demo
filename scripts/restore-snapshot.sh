#!/bin/bash
set -e

TARGET_ENV=$1

if [ "$TARGET_ENV" == "qa" ]; then
  TARGET_API_KEY=$QA_API_KEY
  TARGET_PROJECT_ID=$QA_PROJECT_ID
elif [ "$TARGET_ENV" == "prod" ]; then
  echo "==> Skipping restore for prod — endpoint assignment only"
  echo "==> Prod never uses Restore to preserve rollback safety"
  exit 0
else
  echo "ERROR: Use 'qa' or 'prod'"
  exit 1
fi

SNAPSHOT_ID=$(cat ./snapshots/${TARGET_ENV}_snapshot_id.txt)
echo "==> Restoring snapshot $SNAPSHOT_ID into $TARGET_ENV..."

RESTORE_RESPONSE=$(curl -s -X POST \
  "$COGNIGY_BASE_URL/v2.0/snapshots/$SNAPSHOT_ID/restore" \
  -H "X-API-Key: $TARGET_API_KEY" \
  -H "Content-Type: application/json")

echo "Restore response: $RESTORE_RESPONSE"

# Extract task ID from restore response
TASK_ID=$(echo "$RESTORE_RESPONSE" | jq -r '._id // empty')

if [ -z "$TASK_ID" ]; then
  echo "ERROR: Could not extract restore task ID"
  exit 1
fi

echo "==> Restore task queued: $TASK_ID"

# Poll for completion — check every 15 seconds, up to 10 attempts (2.5 min max)
MAX_ATTEMPTS=10
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  echo "==> Checking restore status (attempt $ATTEMPT of $MAX_ATTEMPTS)..."
  sleep 15

  TASK_RESPONSE=$(curl -s -X GET \
    "$COGNIGY_BASE_URL/v2.0/tasks/$TASK_ID" \
    -H "X-API-Key: $TARGET_API_KEY")

  TASK_STATUS=$(echo "$TASK_RESPONSE" | jq -r '.status // empty')
  TASK_PROGRESS=$(echo "$TASK_RESPONSE" | jq -r '.progress // 0')

  echo "==> Status: $TASK_STATUS | Progress: $TASK_PROGRESS%"

  if [ "$TASK_STATUS" == "done" ] || [ "$TASK_STATUS" == "completed" ]; then
    echo "==> Restore completed successfully ✅"
    exit 0
  fi

  if [ "$TASK_STATUS" == "error" ] || [ "$TASK_STATUS" == "failed" ]; then
    echo "ERROR: Restore task failed"
    echo "Full task response: $TASK_RESPONSE"
    exit 1
  fi

  ATTEMPT=$((ATTEMPT + 1))
done

echo "ERROR: Restore timed out after $((MAX_ATTEMPTS * 15)) seconds"
exit 1
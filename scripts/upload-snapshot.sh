#!/bin/bash
set -e

TARGET_ENV=$1

SNAPSHOT_FILE=$(cat ./snapshots/snapshot_path.txt)

if [ ! -f "$SNAPSHOT_FILE" ]; then
  echo "ERROR: Snapshot file not found at: $SNAPSHOT_FILE"
  exit 1
fi

if [ "$TARGET_ENV" == "qa" ]; then
  TARGET_API_KEY=$QA_API_KEY
  TARGET_PROJECT_ID=$QA_PROJECT_ID
elif [ "$TARGET_ENV" == "prod" ]; then
  TARGET_API_KEY=$PROD_API_KEY
  TARGET_PROJECT_ID=$PROD_PROJECT_ID
else
  echo "ERROR: Use 'qa' or 'prod'"
  exit 1
fi

SNAPSHOT_NAME=$(cat ./snapshots/snapshot_name.txt)
echo "==> Uploading snapshot to $TARGET_ENV (project: $TARGET_PROJECT_ID)..."
echo "==> File: $SNAPSHOT_FILE"
echo "==> Snapshot name: $SNAPSHOT_NAME"

UPLOAD_RESPONSE=$(curl -s -X POST "$COGNIGY_BASE_URL/v2.0/snapshots/upload" \
  -H "X-API-Key: $TARGET_API_KEY" \
  -F "projectId=$TARGET_PROJECT_ID" \
  -F "file=@$SNAPSHOT_FILE")

echo "Upload response: $UPLOAD_RESPONSE"

TASK_ID=$(echo "$UPLOAD_RESPONSE" | jq -r '._id // empty')

if [ -z "$TASK_ID" ]; then
  echo "ERROR: Could not extract task ID from upload response"
  exit 1
fi

echo "==> Upload task queued: $TASK_ID"
echo "==> Waiting 30 seconds for upload task to complete..."
sleep 30

# Query snapshots list and find the one matching our snapshot name
echo "==> Fetching snapshot ID by name: $SNAPSHOT_NAME"

SNAPSHOTS_RESPONSE=$(curl -s -X GET \
  "$COGNIGY_BASE_URL/v2.0/snapshots?projectId=$TARGET_PROJECT_ID" \
  -H "X-API-Key: $TARGET_API_KEY")

echo "Snapshots response: $SNAPSHOTS_RESPONSE"

NEW_SNAPSHOT_ID=$(echo "$SNAPSHOTS_RESPONSE" | jq -r \
  --arg name "$SNAPSHOT_NAME" \
  '._embedded.snapshots[] | select(.name == $name) | .snapshotId // empty' | head -1)

if [ -z "$NEW_SNAPSHOT_ID" ]; then
  echo "ERROR: Could not find snapshot with name '$SNAPSHOT_NAME' in $TARGET_ENV"
  echo "==> Available snapshots:"
  echo "$SNAPSHOTS_RESPONSE" | jq '[._embedded.snapshots[] | {id: .snapshotId, name: .name}]'
  exit 1
fi

echo "==> Snapshot ID in $TARGET_ENV: $NEW_SNAPSHOT_ID"
echo "$NEW_SNAPSHOT_ID" > ./snapshots/${TARGET_ENV}_snapshot_id.txt
echo "==> Snapshot ID saved."
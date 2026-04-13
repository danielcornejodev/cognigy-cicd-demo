#!/bin/bash
set -e

TARGET_ENV=$1  # "qa" or "prod"

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

echo "==> Uploading snapshot to $TARGET_ENV (project: $TARGET_PROJECT_ID)..."
echo "==> File: $SNAPSHOT_FILE"

UPLOAD_RESPONSE=$(curl -s -X POST "$COGNIGY_BASE_URL/v2.0/snapshots/upload" \
  -H "X-API-Key: $TARGET_API_KEY" \
  -F "projectId=$TARGET_PROJECT_ID" \
  -F "file=@$SNAPSHOT_FILE")

echo "Upload response: $UPLOAD_RESPONSE"

# Extract the new snapshot ID — try both common field names
NEW_SNAPSHOT_ID=$(echo "$UPLOAD_RESPONSE" | jq -r '._id // .snapshotId // empty')

if [ -z "$NEW_SNAPSHOT_ID" ]; then
  echo "ERROR: Could not extract snapshot ID. Full response above."
  echo "==> Tip: Check the field name in the response and update this script."
  exit 1
fi

echo "==> Snapshot uploaded. ID in $TARGET_ENV: $NEW_SNAPSHOT_ID"
echo "$NEW_SNAPSHOT_ID" > ./snapshots/${TARGET_ENV}_snapshot_id.txt

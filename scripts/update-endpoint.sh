#!/bin/bash
set -e

TARGET_ENV=$1

if [ "$TARGET_ENV" == "qa" ]; then
  TARGET_API_KEY=$QA_API_KEY
  TARGET_ENDPOINT_ID=$QA_ENDPOINT_ID
  FLOW_REF_ID=$QA_FLOW_REF_ID
elif [ "$TARGET_ENV" == "prod" ]; then
  TARGET_API_KEY=$PROD_API_KEY
  TARGET_ENDPOINT_ID=$PROD_ENDPOINT_ID
  FLOW_REF_ID=$PROD_FLOW_REF_ID
else
  echo "ERROR: Use 'qa' or 'prod'"
  exit 1
fi

SNAPSHOT_ID=$(cat ./snapshots/${TARGET_ENV}_snapshot_id.txt)
echo "==> Snapshot ID: $SNAPSHOT_ID"
echo "==> Flow Reference ID: $FLOW_REF_ID"
echo "==> Updating endpoint: $TARGET_ENDPOINT_ID"

curl -s -X PATCH "$COGNIGY_BASE_URL/v2.0/endpoints/$TARGET_ENDPOINT_ID" \
  -H "X-API-Key: $TARGET_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"snapshot\": {
      \"snapshotId\": \"$SNAPSHOT_ID\",
      \"flowId\": \"$FLOW_REF_ID\"
    }
  }"

echo ""
echo "==> Endpoint updated in $TARGET_ENV"
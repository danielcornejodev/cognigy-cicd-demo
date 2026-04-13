#!/bin/bash
set -e

TARGET_ENV=$1

if [ "$TARGET_ENV" == "qa" ]; then
  TARGET_API_KEY=$QA_API_KEY
  TARGET_ENDPOINT_ID=$QA_ENDPOINT_ID
elif [ "$TARGET_ENV" == "prod" ]; then
  TARGET_API_KEY=$PROD_API_KEY
  TARGET_ENDPOINT_ID=$PROD_ENDPOINT_ID
else
  echo "ERROR: Use 'qa' or 'prod'"
  exit 1
fi

SNAPSHOT_ID=$(cat ./snapshots/${TARGET_ENV}_snapshot_id.txt)
echo "==> Snapshot ID to assign: $SNAPSHOT_ID"

# Get the flow reference ID from within the uploaded snapshot
echo "==> Fetching flow reference ID from snapshot resources..."
RESOURCES=$(curl -s -X GET \
  "$COGNIGY_BASE_URL/v2.0/snapshots/$SNAPSHOT_ID/resources?type=flow" \
  -H "X-API-Key: $TARGET_API_KEY")

echo "Resources response: $RESOURCES"

FLOW_REF_ID=$(echo "$RESOURCES" | jq -r '.items[0].referenceId // .items[0]._id // empty')

if [ -z "$FLOW_REF_ID" ]; then
  echo "ERROR: Could not find flow reference ID. Log the resources response above."
  exit 1
fi

echo "==> Flow reference ID: $FLOW_REF_ID"
echo "==> Updating endpoint $TARGET_ENDPOINT_ID..."

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

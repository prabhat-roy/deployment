#!/bin/bash

set -e

KIBANA_HOST="http://kibana.elastic.svc.cluster.local:5601"
ELASTIC_USERNAME="elastic"
ELASTIC_PASSWORD="changeme"
SECRET_NAME="fleet-enrollment-token"
NAMESPACE="elastic"

echo "Waiting for Kibana to be ready..."
until curl -s -u $ELASTIC_USERNAME:$ELASTIC_PASSWORD "$KIBANA_HOST/api/status" | grep -q '"overall":{"level":"available"'; do
  echo "Kibana not ready yet. Waiting 10s..."
  sleep 10
done

echo "Kibana is ready. Creating Fleet enrollment token..."

# Check if token already exists (optional safeguard)
EXISTING_TOKEN=$(curl -s -u $ELASTIC_USERNAME:$ELASTIC_PASSWORD \
  -X GET "$KIBANA_HOST/api/fleet/enrollment_api_keys" \
  -H 'kbn-xsrf: true' | jq -r '.items[] | select(.policy_id=="default") | .api_key')

if [ -z "$EXISTING_TOKEN" ]; then
  TOKEN_RESPONSE=$(curl -s -u $ELASTIC_USERNAME:$ELASTIC_PASSWORD \
    -X POST "$KIBANA_HOST/api/fleet/enrollment_api_keys" \
    -H 'kbn-xsrf: true' \
    -H 'Content-Type: application/json' \
    -d '{"policy_id":"default"}')

  ENROLLMENT_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.item.api_key')
else
  ENROLLMENT_TOKEN="$EXISTING_TOKEN"
fi

if [ -z "$ENROLLMENT_TOKEN" ]; then
  echo "Failed to obtain enrollment token."
  exit 1
fi

echo "Creating Kubernetes secret for enrollment token..."

kubectl delete secret $SECRET_NAME -n $NAMESPACE --ignore-not-found

kubectl create secret generic $SECRET_NAME \
  --from-literal=token="$ENROLLMENT_TOKEN" \
  -n $NAMESPACE

echo "Enrollment token secret created in namespace '$NAMESPACE'."

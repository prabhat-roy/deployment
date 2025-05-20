#!/bin/bash

# Required variables
ACR_NAME=$1
ACR_LOGIN_SERVER=$2
ENV_FILE="./Jenkins.env"

# Update or append ACR_NAME
if grep -q "^ACR_NAME=" "$ENV_FILE"; then
  sed -i "s/^ACR_NAME=.*/ACR_NAME=${ACR_NAME}/" "$ENV_FILE"
else
  echo "ACR_NAME=${ACR_NAME}" >> "$ENV_FILE"
fi

# Update or append ACR_LOGIN_SERVER
if grep -q "^ACR_LOGIN_SERVER=" "$ENV_FILE"; then
  sed -i "s|^ACR_LOGIN_SERVER=.*|ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}|" "$ENV_FILE"
else
  echo "ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}" >> "$ENV_FILE"
fi

echo "✅ Jenkins.env updated with ACR_NAME=${ACR_NAME} and ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}"

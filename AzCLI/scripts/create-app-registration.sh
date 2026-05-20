#!/bin/bash
set -e

APP_DISPLAY_NAME=$1
ENVIRONMENT=$2

echo "Checking if app registration '$APP_DISPLAY_NAME' already exists..."

# Check for existing app (idempotency)
EXISTING_APP_ID=$(az ad app list \
  --display-name "$APP_DISPLAY_NAME" \
  --query "[0].appId" -o tsv)

if [ -n "$EXISTING_APP_ID" ] && [ "$EXISTING_APP_ID" != "None" ]; then
  echo "App registration already exists with appId: $EXISTING_APP_ID"
  APP_ID=$EXISTING_APP_ID
else
  echo "Creating app registration..."
  APP_ID=$(az ad app create \
    --display-name "$APP_DISPLAY_NAME" \
    --sign-in-audience "AzureADMyOrg" \
    --query appId -o tsv)
  echo "Created app registration with appId: $APP_ID"
fi

# Create service principal if it doesn't exist
echo "Ensuring service principal exists..."
az ad sp show --id "$APP_ID" &>/dev/null || az ad sp create --id "$APP_ID"

# Output the app ID for use in later pipeline stages
echo "##vso[task.setvariable variable=APP_ID;isOutput=true]$APP_ID"
echo "App registration complete. App ID: $APP_ID"
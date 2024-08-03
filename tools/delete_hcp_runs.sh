#!/bin/bash

# Set your HCP organization and project
HCP_ORG_ID="CSP-ETH"
HCP_PROJECT_ID="PROD"

# HCP API endpoint
HCP_API_URL="https://api.cloud.hashicorp.com/v1"

# Check if HCP_API_TOKEN is set
if [ -z "$HCP_API_TOKEN" ]; then
  echo "HCP_API_TOKEN is not set. Please export your API token as HCP_API_TOKEN."
  exit 1
fi

# Fetch the list of HCP runs
response=$(curl -s -H "Authorization: Bearer $HCP_API_TOKEN" "$HCP_API_URL/organizations/$HCP_ORG_ID/projects/$HCP_PROJECT_ID/runs")

# Parse the run IDs from the response
run_ids=$(echo "$response" | jq -r '.runs[].id')

if [ -z "$run_ids" ]; then
  echo "No runs found."
  exit 0
fi

# Loop through each run ID and delete it
for run_id in $run_ids; do
  echo "Deleting run $run_id..."
  curl -s -X DELETE -H "Authorization: Bearer $HCP_API_TOKEN" "$HCP_API_URL/organizations/$HCP_ORG_ID/projects/$HCP_PROJECT_ID/runs/$run_id"
  echo "Run $run_id deleted."
done

echo "All HCP runs have been deleted."

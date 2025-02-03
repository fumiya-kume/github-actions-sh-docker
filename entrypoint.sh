#!/bin/bash
set -e

# Ensure RUNNER_URL is set (expected format: https://github.com/owner/repo)
if [ -z "$RUNNER_URL" ]; then
  echo "Error: RUNNER_URL is not set."
  exit 1
fi

# If RUNNER_TOKEN is not provided, attempt to retrieve it automatically using GITHUB_RUNNER_PAT
if [ -z "$RUNNER_TOKEN" ]; then
  if [ -z "$GITHUB_RUNNER_PAT" ]; then
    echo "Error: Neither RUNNER_TOKEN nor GITHUB_RUNNER_PAT is set. Provide one of them to register the runner."
    exit 1
  fi

  # Extract the owner and repo from RUNNER_URL (assumes format: https://github.com/owner/repo)
  owner_repo=$(echo "$RUNNER_URL" | awk -F'/' '{print $(NF-1)"/"$NF}')
  echo "Detected repository: $owner_repo"

  # Construct the API endpoint URL for getting the runner registration token
  registration_url="https://api.github.com/repos/${owner_repo}/actions/runners/registration-token"
  echo "Requesting runner registration token from: $registration_url"

  # Make a POST request to get the runner token
  RUNNER_TOKEN=$(curl -s -X POST \
    -H "Authorization: token ${GITHUB_RUNNER_PAT}" \
    -H "Accept: application/vnd.github.v3+json" \
    "$registration_url" | jq -r '.token')

  # Validate that the token was retrieved successfully
  if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" == "null" ]; then
    echo "Error: Failed to retrieve runner token automatically. Check your GITHUB_RUNNER_PAT and repository permissions."
    exit 1
  fi

  echo "Successfully retrieved runner token."
fi

# Set a default runner name if not provided; use the container's hostname
if [ -z "$RUNNER_NAME" ]; then
  RUNNER_NAME=$(hostname)
fi

# Configure the GitHub Actions runner
echo "Configuring runner with URL: $RUNNER_URL, name: $RUNNER_NAME"
./config.sh --unattended --url "$RUNNER_URL" --token "$RUNNER_TOKEN" --name "$RUNNER_NAME"

# Start the runner to process jobs
echo "Starting runner..."
./run.sh

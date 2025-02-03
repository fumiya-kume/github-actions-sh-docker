#!/bin/bash
set -e

# Function to display the help message
show_help() {
cat <<EOF
Usage: docker run [OPTIONS] IMAGE

This container registers a GitHub Actions self-hosted runner and processes jobs.

Required environment variables:
  RUNNER_URL         The GitHub repository or organization URL (e.g., https://github.com/owner/repo).
  RUNNER_TOKEN       The token for registering the runner. Alternatively, you can provide GITHUB_RUNNER_PAT.
                     If not provided, the container will attempt to fetch the token automatically.

Optional environment variables:
  GITHUB_RUNNER_PAT  A GitHub Personal Access Token with permissions to retrieve a runner token.
  RUNNER_NAME        The name for the runner. Defaults to the container's hostname if not set.

Examples:
  docker run -e RUNNER_URL=https://github.com/owner/repo -e RUNNER_TOKEN=<token> your-runner-image
  docker run -e RUNNER_URL=https://github.com/owner/repo -e GITHUB_RUNNER_PAT=<pat> your-runner-image

EOF
}

# Check for help flag or unrecognized arguments.
if [[ "$#" -gt 0 ]]; then
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
  else
    echo "Error: Unrecognized argument: $1" >&2
    show_help
    exit 1
  fi
fi

# Ensure RUNNER_URL is set
if [ -z "$RUNNER_URL" ]; then
  echo "Error: RUNNER_URL environment variable is not set." >&2
  show_help
  exit 1
fi

# If RUNNER_TOKEN is not provided, attempt to retrieve it using GITHUB_RUNNER_PAT
if [ -z "$RUNNER_TOKEN" ]; then
  if [ -z "$GITHUB_RUNNER_PAT" ]; then
    echo "Error: Neither RUNNER_TOKEN nor GITHUB_RUNNER_PAT is set. Provide one to register the runner." >&2
    show_help
    exit 1
  fi

  # Extract owner and repository from RUNNER_URL (assumes format: https://github.com/owner/repo)
  owner_repo=$(echo "$RUNNER_URL" | awk -F'/' '{print $(NF-1)"/"$NF}')
  echo "Detected repository: $owner_repo"

  # Construct the API endpoint URL for generating the registration token
  registration_url="https://api.github.com/repos/${owner_repo}/actions/runners/registration-token"
  echo "Requesting runner registration token from: $registration_url"

  # Retrieve the runner token using the GitHub Personal Access Token (PAT)
  RUNNER_TOKEN=$(curl -s -X POST \
    -H "Authorization: token ${GITHUB_RUNNER_PAT}" \
    -H "Accept: application/vnd.github.v3+json" \
    "$registration_url" | jq -r '.token')

  # Validate that the token was retrieved successfully
  if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" = "null" ]; then
    echo "Error: Failed to retrieve runner token automatically." >&2
    exit 1
  fi

  echo "Successfully retrieved runner token."
fi

# Set a default runner name if not provided; defaults to the container's hostname.
if [ -z "$RUNNER_NAME" ]; then
  RUNNER_NAME=$(hostname)
fi

echo "Configuring runner with URL: $RUNNER_URL and Name: $RUNNER_NAME"
./config.sh --unattended --url "$RUNNER_URL" --token "$RUNNER_TOKEN" --name "$RUNNER_NAME"

echo "Starting runner..."
./run.sh

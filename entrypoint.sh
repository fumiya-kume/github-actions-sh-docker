#!/bin/bash
set -e

# Verify that the required environment variables are set
if [ -z "$RUNNER_TOKEN" ]; then
  echo "Error: RUNNER_TOKEN is not set."
  exit 1
fi

if [ -z "$RUNNER_URL" ]; then
  echo "Error: RUNNER_URL is not set."
  exit 1
fi

# Set a default runner name if not provided (using the hostname)
if [ -z "$RUNNER_NAME" ]; then
  RUNNER_NAME=$(hostname)
fi

# Configure the runner with the provided token, URL, and name
./config.sh --unattended --url "$RUNNER_URL" --token "$RUNNER_TOKEN" --name "$RUNNER_NAME"

# Start the runner to listen for jobs
./run.sh

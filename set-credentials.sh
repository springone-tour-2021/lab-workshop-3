#!/usr/bin/bash

# Get user input

# Set GitHub credentials for git and hub CLIs so that user is not prompted multiple times to log in
# Do not change the names of the GITHUB env vars
# hub CLI uses GITHUB_USERNAME and GITHUB_TOKEN env vars

echo -n "Enter your GitHub username [${GITHUB_USERNAME}]: " && read GITHUB_USERNAME
export GITHUB_USERNAME

echo -n "Enter your GitHub auth token: " && read -s GITHUB_TOKEN || { stty -echo; read GITHUB_TOKEN; stty echo; }
export GITHUB_TOKEN
echo

echo -n "Enter your GitHub org name [${GITHUB_USERNAME}]: " && read GITHUB_ORG
GITHUB_ORG="${GITHUB_ORG:-$GITHUB_USERNAME}"
export GITHUB_ORG
echo


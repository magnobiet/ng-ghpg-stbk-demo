#!/bin/bash
set -euo pipefail

badge="![Should I Deploy?]($SHOULDIDEPLOY_BADGE_URL)"
description="Unable to query the API."

response=""

set +e
response="$(curl -s "$SHOULDIDEPLOY_API_URL" 2>/dev/null)"
curl_exit_code=$?
set -e

if [[ $curl_exit_code -ne 0 ]] || [[ -z "$response" ]]; then
  echo "## Should I Deploy?" >> "$GITHUB_STEP_SUMMARY"
  echo "" >> "$GITHUB_STEP_SUMMARY"
  echo "$badge" >> "$GITHUB_STEP_SUMMARY"
  echo "$description" >> "$GITHUB_STEP_SUMMARY"

  exit 1
fi

if [[ "$response" =~ \[shouldideploy\][[:space:]](YES|NO):(.*) ]]; then
  decision="${BASH_REMATCH[1]}"
  message="${BASH_REMATCH[2]# }"
else
  echo "Unexpected response: $response" >&2

  exit 1
fi

description="$message"

if [[ "$decision" == "YES" ]]; then
  echo "Deployment is allowed."
elif [[ "$decision" == "NO" ]]; then
  echo "Deployment is blocked."
  echo "## Should I Deploy?" >> "$GITHUB_STEP_SUMMARY"
  echo "" >> "$GITHUB_STEP_SUMMARY"
  echo "$badge" >> "$GITHUB_STEP_SUMMARY"
  echo "$description" >> "$GITHUB_STEP_SUMMARY"

  exit 1
fi

echo "## Should I Deploy?" >> "$GITHUB_STEP_SUMMARY"
echo "" >> "$GITHUB_STEP_SUMMARY"
echo "$badge" >> "$GITHUB_STEP_SUMMARY"
echo "$description" >> "$GITHUB_STEP_SUMMARY"

#!/usr/bin/env bash
# parse-snyk-output.sh
#
# Reads raw Snyk output (with ANSI color codes), strips colors,
# extracts the relevant summary lines, and appends them to GITHUB_STEP_SUMMARY.
#
# Usage:
#   ./parse-snyk-output.sh <snyk_log_file> <exit_code>
#
# Arguments:
#   snyk_log_file  Path to the file containing raw Snyk output
#   exit_code      The exit code returned by Snyk (0 = success, non-zero = issues found)

set -euo pipefail

SNYK_LOG_FILE="${1:?Missing snyk log file argument}"
EXIT_CODE="${2:?Missing exit code argument}"

# ---------------------------------------------------------------------------
# 1. Strip ANSI color/escape codes from the raw log
# ---------------------------------------------------------------------------
clean_output() {
  sed 's/\x1B\[[0-9;]*[mGKHF]//g' "$1"
}

CLEAN_LOG=$(clean_output "$SNYK_LOG_FILE")

# ---------------------------------------------------------------------------
# 2. Extract the relevant portion of the Snyk report
#    Success: single "✔ Tested …" line
#    Failure: everything from "Tested N dependencies…" through end of issues
# ---------------------------------------------------------------------------
if [ "$EXIT_CODE" -eq 0 ]; then
  # Success — grab the "✔ Tested … no vulnerable paths found." line
  SUMMARY_LINE=$(echo "$CLEAN_LOG" | grep -E "^✔ Tested .* no vulnerable paths found\." || true)

  if [ -z "$SUMMARY_LINE" ]; then
    # Fallback: grab any "Tested … no vulnerable paths found" line (without checkmark)
    SUMMARY_LINE=$(echo "$CLEAN_LOG" | grep -E "Tested .* no vulnerable paths found\." || true)
  fi

  STATUS="✅ Passed"
  {
    echo "## Snyk Vulnerabilities — $STATUS"
    echo ""
    echo "\`\`\`"
    echo "${SUMMARY_LINE:-No summary line found in Snyk output.}"
    echo "\`\`\`"
  } >> "$GITHUB_STEP_SUMMARY"

else
  # Failure — extract from "Tested N dependencies…" to end of issues block
  # The block ends before the "Organization:" metadata lines
  ISSUES_BLOCK=$(echo "$CLEAN_LOG" | \
    awk '/^Tested [0-9]+ dependencies for known issues,/{found=1} found && /^Organization:/{exit} found{print}')

  if [ -z "$ISSUES_BLOCK" ]; then
    # Fallback: dump everything after the first "Testing …" line, minus metadata footer
    ISSUES_BLOCK=$(echo "$CLEAN_LOG" | \
      awk '/^Testing /{found=1; next} found && /^Organization:/{exit} found{print}')
  fi

  STATUS="❌ Failed"
  {
    echo "## Snyk Vulnerabilities — $STATUS"
    echo ""
    echo "\`\`\`"
    echo "${ISSUES_BLOCK:-Could not extract issues from Snyk output.}"
    echo "\`\`\`"
  } >> "$GITHUB_STEP_SUMMARY"
fi

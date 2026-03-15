#!/bin/bash
# push_to_github.sh - Automation for staging, committing, and pushing changes

set -e # Exit on error

echo "--- Starting Git Push Automation ---"

# 1. Clean up temporary files
echo "Cleaning up Vivado artifacts..."
make clean

# 2. Add changes
echo "Staging files..."
git add .

# 3. Prompt for commit message or use default
if [ -z "$1" ]; then
    COMMIT_MSG="chore: update project and benchmarks"
else
    COMMIT_MSG="$1"
fi

# 4. Commit and Push
echo "Committing: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"

echo "Pushing to main branch..."
git push origin main

echo "Done!"

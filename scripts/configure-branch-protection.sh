#!/bin/bash

# Script to configure GitHub branch protection for trunk-based development
# This implements the required pull request approvals for the challenge

REPO_OWNER="anllacarpro"
REPO_NAME="mibanco-devsecops"

echo "Configuring branch protection rules for trunk-based development..."

# Configure branch protection for main branch
gh api repos/${REPO_OWNER}/${REPO_NAME}/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["build"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":false}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false

echo "✅ Branch protection configured for main branch:"
echo "  - Requires 1 pull request approval"
echo "  - Requires status checks to pass (build job)"
echo "  - Dismisses stale reviews when new commits are pushed"
echo "  - Prevents force pushes and branch deletion"
echo "  - Enforces rules for administrators"

echo ""
echo "📋 To use this script:"
echo "1. Install GitHub CLI: gh auth login"
echo "2. Replace REPO_OWNER and REPO_NAME with your values"
echo "3. Run: ./scripts/configure-branch-protection.sh"

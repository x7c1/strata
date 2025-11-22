#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}Success: $1${NC}"
}

print_info() {
    echo -e "${YELLOW}Info: $1${NC}"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository"
    exit 1
fi

# Check if GitHub CLI is authenticated
if ! gh auth status > /dev/null 2>&1; then
    print_error "GitHub CLI is not authenticated. Please run 'gh auth login' first."
    exit 1
fi

# Get current branch name
CURRENT_BRANCH=$(git branch --show-current)

# Check if we're on main branch
if [ "$CURRENT_BRANCH" = "main" ]; then
    print_error "Cannot create PR from main branch"
    exit 1
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    print_error "You have uncommitted changes. Please commit or stash them first."
    exit 1
fi

# Check if PR already exists for this branch
if gh pr view "$CURRENT_BRANCH" > /dev/null 2>&1; then
    print_error "PR already exists for branch '$CURRENT_BRANCH'"
    exit 1
fi

print_info "Pushing branch '$CURRENT_BRANCH' to remote..."

# Push current branch with upstream tracking
if ! git push -u origin "$CURRENT_BRANCH"; then
    print_error "Failed to push branch to remote"
    exit 1
fi

print_info "Getting first commit date from branch..."

# Get the first commit date of the current branch (since it diverged from main)
FIRST_COMMIT_DATE=$(git log main..HEAD --reverse --format="%ad" --date=format:"%Y-%m-%d" | head -n 1)

if [ -z "$FIRST_COMMIT_DATE" ]; then
    print_error "Could not determine first commit date. Make sure the branch has commits different from main."
    exit 1
fi

# Generate PR title
PR_TITLE="since $FIRST_COMMIT_DATE"

print_info "Creating draft PR with title: '$PR_TITLE'"

# Create draft PR with empty description
if ! PR_URL=$(gh pr create --title "$PR_TITLE" --body "" --draft); then
    print_error "Failed to create PR"
    exit 1
fi

print_success "Draft PR created successfully!"
print_info "PR URL: $PR_URL"

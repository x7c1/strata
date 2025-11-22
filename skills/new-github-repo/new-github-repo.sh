#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables for configuration
REPO_NAME=""
REPO_DESCRIPTION=""
REPO_VISIBILITY="public"
REPO_OWNER=""
DEFAULT_BRANCH="main"
DELETE_BRANCH_ON_MERGE="true"
ALLOW_SQUASH_MERGE="true"
ALLOW_MERGE_COMMIT="false"
ALLOW_REBASE_MERGE="false"
REQUIRED_APPROVING_REVIEW_COUNT="1"
REQUIRE_STATUS_CHECKS="true"
ALLOW_FORCE_PUSHES="false"
ENFORCE_ADMINS="true"

# Main function
main() {
    local config_file="$1"

    # Show usage if no arguments provided
    if [ -z "$config_file" ]; then
        show_usage
        exit 1
    fi

    # Validate configuration file exists
    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi

    print_info "Starting GitHub repository creation process..."

    # Check prerequisites
    check_prerequisites

    # Get repository owner (once)
    REPO_OWNER=$(get_repo_owner)
    print_debug "Repository owner: $REPO_OWNER"

    # Parse YAML configuration
    print_info "Parsing configuration file: $config_file"
    parse_yaml "$config_file"

    # Validate configuration
    validate_config

    # Create repository
    print_info "Creating repository: $REPO_NAME"
    create_repository

    # Create initial files
    print_info "Creating initial files..."
    create_initial_files

    # Configure repository settings
    print_info "Configuring repository settings..."
    configure_repository_settings

    # Apply branch protection rules
    print_info "Applying branch protection rules..."
    apply_branch_protection

    print_success "Repository '$REPO_NAME' created and configured successfully!"
    print_info "Repository URL: https://github.com/$REPO_OWNER/$REPO_NAME"
}

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

print_debug() {
    echo -e "${BLUE}Debug: $1${NC}"
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $(basename "$0") CONFIG_FILE

Create a new GitHub repository with predefined settings and branch protection rules.

Arguments:
    CONFIG_FILE    Path to YAML configuration file

Example:
    $(basename "$0") example.yaml

Configuration File Format:
    See example.yaml for a complete example with all available options.

Requirements:
    - GitHub CLI (gh) must be installed and authenticated
    - User must have permission to create repositories

EOF
}

# Check if prerequisites are met
check_prerequisites() {
    # Check if gh is installed
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed. Please install it first."
        print_info "Visit: https://cli.github.com/"
        exit 1
    fi

    # Check if gh is authenticated
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated. Please run 'gh auth login' first."
        exit 1
    fi

    # Configure git to use gh as credential helper
    print_debug "Configuring git authentication with gh"
    gh auth setup-git

    # Check if yq is installed
    if ! command -v yq &> /dev/null; then
        print_error "yq is not installed. Please install it first."
        print_info "Install with: sudo apt-get install yq"
        exit 1
    fi

    print_debug "Prerequisites check passed"
}

# Get repository owner (authenticated user or organization)
get_repo_owner() {
    gh api user --jq '.login'
}

# Check if repository already exists
repo_exists() {
    gh repo view "$REPO_OWNER/$REPO_NAME" &> /dev/null
    return $?
}

# Parse YAML configuration file using yq
parse_yaml() {
    local config_file="$1"

    # Parse top-level fields
    REPO_NAME=$(yq -r '.name // ""' "$config_file")
    REPO_DESCRIPTION=$(yq -r '.description // ""' "$config_file")
    REPO_VISIBILITY=$(yq -r '.visibility // "public"' "$config_file")
    DEFAULT_BRANCH=$(yq -r '.default_branch // "main"' "$config_file")
    DELETE_BRANCH_ON_MERGE=$(yq -r '.delete_branch_on_merge // "true"' "$config_file")

    # Parse merge_methods section
    ALLOW_SQUASH_MERGE=$(yq -r '.merge_methods.allow_squash_merge // "true"' "$config_file")
    ALLOW_MERGE_COMMIT=$(yq -r '.merge_methods.allow_merge_commit // "false"' "$config_file")
    ALLOW_REBASE_MERGE=$(yq -r '.merge_methods.allow_rebase_merge // "false"' "$config_file")

    # Parse branch_protection section
    REQUIRED_APPROVING_REVIEW_COUNT=$(yq -r '.branch_protection.required_approving_review_count // "1"' "$config_file")
    REQUIRE_STATUS_CHECKS=$(yq -r '.branch_protection.require_status_checks // "true"' "$config_file")
    ALLOW_FORCE_PUSHES=$(yq -r '.branch_protection.allow_force_pushes // "false"' "$config_file")
    ENFORCE_ADMINS=$(yq -r '.branch_protection.enforce_admins // "true"' "$config_file")

    print_debug "Configuration parsed successfully"
}

# Validate configuration
validate_config() {
    # Repository name is required
    if [ -z "$REPO_NAME" ]; then
        print_error "Repository name is required in configuration file"
        exit 1
    fi

    # Validate visibility
    if [[ ! "$REPO_VISIBILITY" =~ ^(public|private|internal)$ ]]; then
        print_error "Invalid visibility: $REPO_VISIBILITY (must be: public, private, or internal)"
        exit 1
    fi

    print_debug "Configuration validated successfully"
}

# Create repository
create_repository() {
    # Check if repository already exists
    if repo_exists; then
        print_info "Repository already exists, skipping creation"
        return 0
    fi

    local visibility_flag="--$REPO_VISIBILITY"
    local description_flag=""

    if [ -n "$REPO_DESCRIPTION" ]; then
        description_flag="--description"
    fi

    # Create repository
    if [ -n "$description_flag" ]; then
        gh repo create "$REPO_NAME" "$visibility_flag" "$description_flag" "$REPO_DESCRIPTION"
    else
        gh repo create "$REPO_NAME" "$visibility_flag"
    fi

    print_debug "Repository created: $REPO_NAME"
}

# Copy infrastructure files to repository
copy_infrastructure_files() {
    local temp_dir="$1"
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local templates_dir="$script_dir/templates"

    print_debug "Copying infrastructure files from: $templates_dir"

    # Copy Dockerfile (prepared from template before script execution)
    if [ -f "$templates_dir/../Dockerfile" ]; then
        cp "$templates_dir/../Dockerfile" "$temp_dir/repo/"
        print_debug "Copied Dockerfile"
    fi

    # Copy docker-compose.yml
    if [ -f "$templates_dir/docker-compose.yml" ]; then
        cp "$templates_dir/docker-compose.yml" "$temp_dir/repo/"
        print_debug "Copied docker-compose.yml"
    fi

    # Copy Makefile
    if [ -f "$templates_dir/Makefile" ]; then
        cp "$templates_dir/Makefile" "$temp_dir/repo/"
        print_debug "Copied Makefile"
    fi

    # Create scripts directory and copy install-ubuntu-deps.sh
    mkdir -p "$temp_dir/repo/scripts"
    if [ -f "$templates_dir/scripts/install-ubuntu-deps.sh" ]; then
        cp "$templates_dir/scripts/install-ubuntu-deps.sh" "$temp_dir/repo/scripts/"
        chmod +x "$temp_dir/repo/scripts/install-ubuntu-deps.sh"
        print_debug "Copied scripts/install-ubuntu-deps.sh"
    fi
}

# Create initial files
create_initial_files() {
    # Check if default branch already exists
    if gh api "repos/$REPO_OWNER/$REPO_NAME/branches/$DEFAULT_BRANCH" &> /dev/null; then
        print_info "Branch '$DEFAULT_BRANCH' already exists, skipping initial files creation"
        return 0
    fi

    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || exit 1

    # Clone the empty repository using gh (handles authentication automatically)
    gh repo clone "$REPO_OWNER/$REPO_NAME" repo
    cd repo || exit 1

    # Create default branch if needed
    git checkout -b "$DEFAULT_BRANCH" 2>/dev/null || git checkout "$DEFAULT_BRANCH"

    # Create empty README.md and .gitignore
    touch README.md
    touch .gitignore

    # Copy infrastructure files
    copy_infrastructure_files "$temp_dir"

    # Commit all files
    git add .
    git commit -m "Initial commit with infrastructure setup"

    # Push to remote (gh authentication is already configured)
    git push -u origin "$DEFAULT_BRANCH"

    # Clean up
    cd - > /dev/null || exit 1
    rm -rf "$temp_dir"

    print_debug "Initial infrastructure files created and pushed"
}

# Configure repository settings
configure_repository_settings() {
    # Convert boolean strings to JSON boolean values
    local delete_branch_json
    local squash_merge_json
    local merge_commit_json
    local rebase_merge_json

    [[ "$DELETE_BRANCH_ON_MERGE" == "true" ]] && delete_branch_json="true" || delete_branch_json="false"
    [[ "$ALLOW_SQUASH_MERGE" == "true" ]] && squash_merge_json="true" || squash_merge_json="false"
    [[ "$ALLOW_MERGE_COMMIT" == "true" ]] && merge_commit_json="true" || merge_commit_json="false"
    [[ "$ALLOW_REBASE_MERGE" == "true" ]] && rebase_merge_json="true" || rebase_merge_json="false"

    # Update repository settings using GitHub API
    gh api -X PATCH "/repos/$REPO_OWNER/$REPO_NAME" \
        -f delete_branch_on_merge="$delete_branch_json" \
        -f allow_squash_merge="$squash_merge_json" \
        -f allow_merge_commit="$merge_commit_json" \
        -f allow_rebase_merge="$rebase_merge_json" \
        > /dev/null

    print_debug "Repository settings configured"
}

# Apply branch protection rules
apply_branch_protection() {
    # Check if branch exists before applying protection
    if ! gh api "repos/$REPO_OWNER/$REPO_NAME/branches/$DEFAULT_BRANCH" &> /dev/null; then
        print_info "Branch '$DEFAULT_BRANCH' does not exist yet, skipping branch protection"
        return 0
    fi

    # Convert boolean strings to JSON boolean values
    local require_status_checks_json
    local allow_force_pushes_json
    local enforce_admins_json

    [[ "$REQUIRE_STATUS_CHECKS" == "true" ]] && require_status_checks_json="true" || require_status_checks_json="false"
    [[ "$ALLOW_FORCE_PUSHES" == "true" ]] && allow_force_pushes_json="true" || allow_force_pushes_json="false"
    [[ "$ENFORCE_ADMINS" == "true" ]] && enforce_admins_json="true" || enforce_admins_json="false"

    # Build JSON payload for branch protection
    # Note: 'restrictions' is only available for GitHub Pro/Team/Enterprise accounts
    local json_payload
    json_payload=$(cat <<EOF
{
  "required_status_checks": $([ "$require_status_checks_json" = "true" ] && echo '{"strict": true, "contexts": []}' || echo 'null'),
  "enforce_admins": $enforce_admins_json,
  "required_pull_request_reviews": {
    "required_approving_review_count": $REQUIRED_APPROVING_REVIEW_COUNT,
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": $allow_force_pushes_json,
  "allow_deletions": false,
  "required_conversation_resolution": false
}
EOF
)

    # Apply branch protection rules
    if ! gh api -X PUT "/repos/$REPO_OWNER/$REPO_NAME/branches/$DEFAULT_BRANCH/protection" \
        --input - <<< "$json_payload" > /dev/null 2>&1; then
        print_error "Failed to apply branch protection rules"
        print_info "This might be due to account limitations (free accounts have limited branch protection features)"
        print_info "You can manually configure branch protection in the GitHub repository settings"
        return 1
    fi

    print_debug "Branch protection rules applied to $DEFAULT_BRANCH"
}

# Call main function with all arguments
main "$@"

#!/bin/bash

set -e

# Resolve script directory before any cd changes the working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
ALLOW_FORCE_PUSHES="false"

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

    # Apply ruleset
    print_info "Applying ruleset..."
    apply_ruleset

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

Create a new GitHub repository with predefined settings and rulesets.

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

    # Parse ruleset section
    REQUIRED_APPROVING_REVIEW_COUNT=$(yq -r '.ruleset.required_approving_review_count // "1"' "$config_file")
    ALLOW_FORCE_PUSHES=$(yq -r '.ruleset.allow_force_pushes // "false"' "$config_file")

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
    local templates_dir="$SCRIPT_DIR/templates"

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

    # Copy .gitignore
    if [ -f "$templates_dir/.gitignore" ]; then
        cp "$templates_dir/.gitignore" "$temp_dir/repo/"
        print_debug "Copied .gitignore"
    fi

    # Create scripts directory and copy all scripts
    mkdir -p "$temp_dir/repo/scripts"
    if [ -f "$templates_dir/scripts/install-ubuntu-deps.sh" ]; then
        cp "$templates_dir/scripts/install-ubuntu-deps.sh" "$temp_dir/repo/scripts/"
        chmod +x "$temp_dir/repo/scripts/install-ubuntu-deps.sh"
        print_debug "Copied scripts/install-ubuntu-deps.sh"
    fi
    if [ -f "$templates_dir/scripts/setup-claude-container.sh" ]; then
        cp "$templates_dir/scripts/setup-claude-container.sh" "$temp_dir/repo/scripts/"
        chmod +x "$temp_dir/repo/scripts/setup-claude-container.sh"
        print_debug "Copied scripts/setup-claude-container.sh"
    fi
    if [ -f "$templates_dir/scripts/setup-claude-role.sh" ]; then
        cp "$templates_dir/scripts/setup-claude-role.sh" "$temp_dir/repo/scripts/"
        chmod +x "$temp_dir/repo/scripts/setup-claude-role.sh"
        print_debug "Copied scripts/setup-claude-role.sh"
    fi
    if [ -f "$templates_dir/scripts/start-claude-code.sh" ]; then
        cp "$templates_dir/scripts/start-claude-code.sh" "$temp_dir/repo/scripts/"
        chmod +x "$temp_dir/repo/scripts/start-claude-code.sh"
        print_debug "Copied scripts/start-claude-code.sh"
    fi
}

# Add strata submodule to repository
add_submodule() {
    local submodule_repo="git@github.com:x7c1/strata.git"
    local submodule_path="vendor/strata"

    print_debug "Adding strata submodule at $submodule_path"

    # Add submodule
    if ! git submodule add "$submodule_repo" "$submodule_path" 2>&1; then
        print_error "Failed to add submodule from $submodule_repo"
        return 1
    fi

    print_debug "Submodule added successfully"

    # Initialize and update submodule
    if ! git submodule update --init "$submodule_path" 2>&1; then
        print_error "Failed to initialize submodule at $submodule_path"
        return 1
    fi

    print_debug "Submodule initialized successfully"

    return 0
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

    # Add strata submodule
    add_submodule

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

# Apply ruleset to default branch
apply_ruleset() {
    # Check if branch exists before applying ruleset
    if ! gh api "repos/$REPO_OWNER/$REPO_NAME/branches/$DEFAULT_BRANCH" &> /dev/null; then
        print_info "Branch '$DEFAULT_BRANCH' does not exist yet, skipping ruleset"
        return 0
    fi

    # Build rules array
    local rules='[]'

    # Add pull request review requirement
    rules=$(echo "$rules" | jq --argjson count "$REQUIRED_APPROVING_REVIEW_COUNT" '. + [{
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": $count,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    }]')

    # Add force push prevention (non_fast_forward) unless explicitly allowed
    if [[ "$ALLOW_FORCE_PUSHES" != "true" ]]; then
        rules=$(echo "$rules" | jq '. + [{"type": "non_fast_forward"}]')
    fi

    # Add branch deletion prevention
    rules=$(echo "$rules" | jq '. + [{"type": "deletion"}]')

    # Build full payload
    local json_payload
    json_payload=$(jq -n \
      --arg name "$DEFAULT_BRANCH branch protection" \
      --arg branch "refs/heads/$DEFAULT_BRANCH" \
      --argjson rules "$rules" \
      '{
        "name": $name,
        "target": "branch",
        "enforcement": "active",
        "conditions": {
          "ref_name": {
            "include": [$branch],
            "exclude": []
          }
        },
        "rules": $rules
      }')

    # Apply ruleset
    if ! gh api -X POST "/repos/$REPO_OWNER/$REPO_NAME/rulesets" \
        --input - <<< "$json_payload" > /dev/null 2>&1; then
        print_error "Failed to apply ruleset"
        print_info "This might be due to account limitations (free accounts have limited ruleset features for private repos)"
        print_info "You can manually configure rulesets in the GitHub repository settings"
        return 1
    fi

    print_debug "Ruleset applied to $DEFAULT_BRANCH"
}

# Call main function with all arguments
main "$@"

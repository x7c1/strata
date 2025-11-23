#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FORMAT_STAGED_SCRIPT="$SCRIPT_DIR/format-staged-files.sh"

main() {
    local commit_msg="$1"

    if [ -z "$commit_msg" ]; then
        print_error "Commit message is required"
        show_usage
        exit 1
    fi

    validate_commit_message "$commit_msg"

    print_info "Starting git commit process..."

    check_prerequisites

    print_info "Formatting staged files..."
    format_staged_files

    if ! has_staged_changes; then
        print_error "No changes staged for commit"
        exit 1
    fi

    print_info "Creating commit with message: $commit_msg"
    echo ""

    create_commit "$commit_msg"

    print_success "Commit created successfully!"
    echo ""
    git log -1 --oneline
}

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

show_usage() {
    cat << EOF
Usage: $(basename "$0") COMMIT_MESSAGE

Create a git commit with the provided conventional commit message.

Arguments:
    COMMIT_MESSAGE    Conventional commit message (e.g., "feat(scope): description")

Example:
    $(basename "$0") "feat(auth): add login functionality"

EOF
}

validate_commit_message() {
    local commit_msg="$1"

    local forbidden_patterns=(
        "Files Added"
        "Files Modified"
        "Files Changed"
        "Generated with"
    )

    for pattern in "${forbidden_patterns[@]}"; do
        if echo "$commit_msg" | grep -q "$pattern"; then
            print_error "Commit message contains unnecessary '$pattern' section - please remove it"
            exit 1
        fi
    done

    print_debug "Commit message validation passed"
}

check_prerequisites() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi

    if [[ ! -x "$FORMAT_STAGED_SCRIPT" ]]; then
        print_error "format-staged-files.sh not found or not executable at $FORMAT_STAGED_SCRIPT"
        exit 1
    fi

    print_debug "Prerequisites check passed"
}

has_staged_changes() {
    ! git diff --cached --quiet
}

format_staged_files() {
    bash "$FORMAT_STAGED_SCRIPT"
    echo ""
}

create_commit() {
    local commit_msg="$1"

    if ! git commit -m "$commit_msg"; then
        print_error "Failed to create commit"
        exit 1
    fi

    print_debug "Commit created with message: $commit_msg"
}

main "$@"

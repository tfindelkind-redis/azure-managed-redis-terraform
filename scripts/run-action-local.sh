#!/usr/bin/env bash
#
# run-action-local.sh - Interactive GitHub Actions local runner using act
#
# This script provides an interactive menu to run GitHub Actions workflows
# locally using act (https://github.com/nektos/act).
#
# Usage:
#   ./scripts/run-action-local.sh
#
# Requirements:
#   - act (GitHub Actions local runner)
#   - Docker or compatible container runtime (e.g., colima)
#   - jq (for JSON parsing)
#
# Options will be provided interactively:
#   - Select workflow file
#   - Select job within workflow (or run all jobs)
#   - Select event type (push, pull_request, schedule, workflow_dispatch)
#   - Dry-run or actual execution
#

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKFLOWS_DIR="$REPO_ROOT/.github/workflows"

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print section headers
print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check prerequisites
check_prerequisites() {
    local missing=0

    # Check for act
    if ! command -v act &> /dev/null; then
        print_error "act is not installed"
        echo ""
        echo "  Install act:"
        echo "    macOS:   brew install act"
        echo "    Linux:   curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
        echo "    Windows: choco install act-cli"
        echo ""
        echo "  Or visit: https://github.com/nektos/act"
        missing=1
    else
        print_success "act found: $(which act)"
    fi

    # Check for Docker/container runtime
    if ! docker info &> /dev/null; then
        print_error "Docker/container runtime is not running"
        echo ""
        echo "  Start Docker Desktop or colima:"
        echo "    colima start"
        echo ""
        missing=1
    else
        print_success "Container runtime is available"
    fi

    # Check for yq (optional but helpful)
    if ! command -v yq &> /dev/null; then
        print_warning "yq is not installed (optional, for better workflow parsing)"
        echo "  Install: brew install yq"
    fi

    if [ $missing -eq 1 ]; then
        exit 1
    fi
}

# Get list of workflow files
get_workflows() {
    if [ ! -d "$WORKFLOWS_DIR" ]; then
        print_error "Workflows directory not found: $WORKFLOWS_DIR"
        exit 1
    fi

    find "$WORKFLOWS_DIR" \( -name '*.yml' -o -name '*.yaml' \) -type f -exec basename {} \; | sort
}

# Parse workflow file to get job names
get_jobs_from_workflow() {
    local workflow_file="$1"
    local jobs=()

    if command -v yq &> /dev/null; then
        # Use yq if available for accurate parsing
        while IFS= read -r job; do
            [ -n "$job" ] && jobs+=("$job")
        done < <(yq eval '.jobs | keys | .[]' "$workflow_file" 2>/dev/null)
    else
        # Fallback to grep (less accurate but works)
        while IFS= read -r line; do
            if [[ $line =~ ^[[:space:]]*([a-zA-Z0-9_-]+):[[:space:]]*$ ]]; then
                local job_name="${BASH_REMATCH[1]}"
                # Skip common non-job keys
                if [[ ! "$job_name" =~ ^(name|on|env|permissions|concurrency|defaults)$ ]]; then
                    jobs+=("$job_name")
                fi
            fi
        done < <(sed -n '/^jobs:/,/^[a-z]/p' "$workflow_file")
    fi

    echo "${jobs[@]}"
}

# Get event types from workflow
get_event_types() {
    local workflow_file="$1"
    local events=()

    if command -v yq &> /dev/null; then
        while IFS= read -r event; do
            [ -n "$event" ] && events+=("$event")
        done < <(yq eval '.on | keys | .[]' "$workflow_file" 2>/dev/null)
    else
        # Fallback: parse manually
        if grep -q "on:" "$workflow_file"; then
            # Check for common event types
            grep -A 20 "^on:" "$workflow_file" | while IFS= read -r line; do
                if [[ $line =~ ^[[:space:]]*(push|pull_request|workflow_dispatch|schedule|release): ]]; then
                    event="${BASH_REMATCH[1]}"
                    [ -n "$event" ] && echo "$event"
                elif [[ $line =~ ^[[:space:]]+(push|pull_request|workflow_dispatch|schedule|release)$ ]]; then
                    event="${BASH_REMATCH[1]}"
                    [ -n "$event" ] && echo "$event"
                fi
            done | sort -u
        fi
    fi

    # If no events found, provide defaults
    if [ ${#events[@]} -eq 0 ]; then
        events=("push" "pull_request" "workflow_dispatch")
    fi

    printf '%s\n' "${events[@]}"
}

# Interactive menu selection
select_option() {
    local prompt="$1"
    shift
    local options=("$@")

    if [ ${#options[@]} -eq 0 ]; then
        print_error "No options provided to select_option" >&2
        return 1
    fi

    echo "" >&2
    echo -e "${BLUE}$prompt${NC}" >&2
    echo "" >&2

    for i in "${!options[@]}"; do
        echo "  $((i+1)). ${options[$i]}" >&2
    done
    echo "" >&2

    while true; do
        read -p "Enter selection (1-${#options[@]}): " selection >&2
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#options[@]}" ]; then
            echo "${options[$((selection-1))]}"
            return 0
        else
            print_error "Invalid selection. Please enter a number between 1 and ${#options[@]}" >&2
        fi
    done
}

# Main menu
main() {
    cd "$REPO_ROOT"

    print_header "GitHub Actions Local Runner (act)"
    
    print_info "Repository: $(basename "$REPO_ROOT")"
    print_info "Workflows directory: $WORKFLOWS_DIR"
    echo ""

    # Check prerequisites
    check_prerequisites

    # Get workflows
    print_header "Step 1: Select Workflow"
    
    workflows=()
    while IFS= read -r workflow; do
        [ -n "$workflow" ] && workflows+=("$workflow")
    done < <(get_workflows)
    
    print_info "Found ${#workflows[@]} workflow(s)"
    
    # Debug: Show what we found
    if [ "${DEBUG:-0}" = "1" ]; then
        echo "Debug - workflows array contents:"
        for i in "${!workflows[@]}"; do
            echo "  [$i] = '${workflows[$i]}'"
        done
    fi
    
    if [ ${#workflows[@]} -eq 0 ]; then
        print_error "No workflow files found in $WORKFLOWS_DIR"
        exit 1
    fi

    selected_workflow=$(select_option "Available workflows:" "${workflows[@]}")
    select_result=$?
    if [ $select_result -ne 0 ]; then
        print_error "Selection failed"
        exit 1
    fi
    workflow_file="$WORKFLOWS_DIR/$selected_workflow"
    
    print_success "Selected: $selected_workflow"

    # Get jobs
    print_header "Step 2: Select Job"
    
    jobs=()
    while IFS= read -r job; do
        [ -n "$job" ] && jobs+=("$job")
    done < <(get_jobs_from_workflow "$workflow_file")
    
    if [ ${#jobs[@]} -eq 0 ]; then
        print_warning "No jobs found in workflow (will run all jobs)"
        selected_job=""
    else
        # Add "All jobs" option
        job_options=("All jobs" "${jobs[@]}")
        selected_job_option=$(select_option "Available jobs:" "${job_options[@]}")
        
        if [ "$selected_job_option" = "All jobs" ]; then
            selected_job=""
            print_success "Selected: Run all jobs"
        else
            selected_job="$selected_job_option"
            print_success "Selected: $selected_job"
        fi
    fi

    # Get event types
    print_header "Step 3: Select Event Type"
    
    events=()
    while IFS= read -r event; do
        [ -n "$event" ] && events+=("$event")
    done < <(get_event_types "$workflow_file")
    
    if [ ${#events[@]} -eq 0 ]; then
        print_warning "No event types found in workflow"
        print_info "Using default: workflow_dispatch"
        selected_event="workflow_dispatch"
    elif [ ${#events[@]} -eq 1 ]; then
        selected_event="${events[0]}"
        print_info "Workflow supports only: $selected_event"
        print_success "Selected: $selected_event"
    else
        print_info "Workflow supports: ${events[*]}"
        
        # If workflow_dispatch is available, recommend it for local testing
        if [[ " ${events[*]} " =~ " workflow_dispatch " ]]; then
            print_info "💡 Tip: workflow_dispatch is recommended for local testing with act"
        fi
        
        selected_event=$(select_option "Available event types:" "${events[@]}")
        print_success "Selected: $selected_event"
        
        # Warn about schedule events
        if [ "$selected_event" = "schedule" ]; then
            print_warning "Note: 'schedule' events may not work well with act. Consider using 'workflow_dispatch' instead."
            read -p "$(echo -e ${YELLOW}Continue anyway? [y/N]: ${NC})" confirm >&2
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                print_info "Switching to workflow_dispatch..."
                selected_event="workflow_dispatch"
            fi
        fi
    fi

    # Execution mode
    print_header "Step 4: Execution Mode"
    
    exec_modes=("Actual execution" "Dry-run (show what would happen)")
    selected_mode=$(select_option "Select execution mode:" "${exec_modes[@]}")
    
    if [ "$selected_mode" = "Dry-run (show what would happen)" ]; then
        dryrun="--dryrun"
        print_success "Mode: Dry-run"
    else
        dryrun=""
        print_success "Mode: Actual execution"
    fi

    # Platform selection
    print_header "Step 5: Platform Configuration"
    
    platform_options=("Auto-detect" "linux/amd64 (M-series Mac)" "Default")
    selected_platform=$(select_option "Select container platform:" "${platform_options[@]}")
    
    case "$selected_platform" in
        "linux/amd64 (M-series Mac)")
            platform_arg="--container-architecture linux/amd64"
            print_success "Platform: linux/amd64"
            ;;
        "Default")
            platform_arg=""
            print_success "Platform: Default"
            ;;
        *)
            if [[ "$(uname -m)" == "arm64" ]]; then
                platform_arg="--container-architecture linux/amd64"
                print_success "Platform: linux/amd64 (auto-detected M-series Mac)"
            else
                platform_arg=""
                print_success "Platform: Default (auto-detected)"
            fi
            ;;
    esac

    # Build command
    print_header "Running Workflow"
    
    cmd="act $selected_event"
    cmd="$cmd --workflows $workflow_file"
    
    if [ -n "$selected_job" ]; then
        cmd="$cmd --job $selected_job"
    fi
    
    if [ -n "$dryrun" ]; then
        cmd="$cmd $dryrun"
    fi
    
    if [ -n "$platform_arg" ]; then
        cmd="$cmd $platform_arg"
    fi
    
    # Add common platform mapping
    cmd="$cmd -P ubuntu-latest=catthehacker/ubuntu:act-latest"
    
    # Disable Docker socket mounting (prevents colima issues)
    # These workflows don't need Docker-in-Docker
    cmd="$cmd --container-daemon-socket -"
    
    echo ""
    print_info "Command: $cmd"
    echo ""
    
    # Confirm execution
    if [ -z "$dryrun" ]; then
        read -p "$(echo -e ${YELLOW}Proceed with actual execution? [y/N]: ${NC})" confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_warning "Cancelled by user"
            exit 0
        fi
    fi
    
    echo ""
    print_header "Execution Output"
    echo ""
    
    # Execute
    if eval "$cmd"; then
        echo ""
        print_success "Workflow completed successfully!"
    else
        exit_code=$?
        echo ""
        print_error "Workflow failed with exit code $exit_code"
        exit "$exit_code"
    fi
}

# Run main function
main "$@"


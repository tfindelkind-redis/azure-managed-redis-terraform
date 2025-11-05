#!/bin/bash

# Local Testing Script for GitHub Actions Workflows
# This script runs the same checks as CI without requiring commits

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}==>${NC} $1"
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    local install_commands=()
    
    if ! command_exists terraform; then
        missing_tools+=("terraform")
        install_commands+=("brew install terraform")
    fi
    
    if ! command_exists tflint; then
        missing_tools+=("tflint")
        install_commands+=("brew install tflint")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "These tools are needed to run local validation checks."
        echo ""
        
        # Check if we're on macOS with Homebrew
        if [[ "$OSTYPE" == "darwin"* ]] && command_exists brew; then
            echo "Do you want to install missing tools now? (y/n)"
            read -r response
            
            if [[ "$response" =~ ^[Yy]$ ]]; then
                for cmd in "${install_commands[@]}"; do
                    print_status "Running: $cmd"
                    eval "$cmd"
                done
                echo ""
                print_success "All tools installed successfully!"
                return 0
            fi
        fi
        
        echo "Install missing tools manually:"
        for tool in "${missing_tools[@]}"; do
            case $tool in
                terraform)
                    echo ""
                    echo "Terraform:"
                    echo "  macOS:   brew install terraform"
                    echo "  Linux:   https://developer.hashicorp.com/terraform/downloads"
                    echo "  Windows: choco install terraform"
                    ;;
                tflint)
                    echo ""
                    echo "TFLint:"
                    echo "  macOS:   brew install tflint"
                    echo "  Linux:   curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash"
                    echo "  Windows: choco install tflint"
                    ;;
            esac
        done
        echo ""
        exit 1
    fi
    
    print_success "All prerequisites installed"
}

# Terraform formatting check
check_format() {
    print_status "Checking Terraform formatting..."
    
    if terraform fmt -check -recursive -diff; then
        print_success "All files are properly formatted"
        return 0
    else
        print_error "Formatting issues found"
        print_warning "Run 'terraform fmt -recursive' to fix"
        return 1
    fi
}

# Terraform validation
check_validate() {
    print_status "Running Terraform validation..."
    
    local failed=0
    local dirs=(
        "modules/managed-redis"
        "examples/simple"
        "examples/with-modules"
        "examples/high-availability"
        "examples/geo-replication"
        "examples/clusterless-with-persistence"
        "examples/enterprise-security"
    )
    
    for dir in "${dirs[@]}"; do
        echo ""
        print_status "Validating: $dir"
        
        if ! (cd "$dir" && terraform init -backend=false -upgrade > /dev/null 2>&1); then
            print_error "Failed to initialize $dir"
            failed=1
            continue
        fi
        
        if (cd "$dir" && terraform validate); then
            print_success "Validation passed: $dir"
        else
            print_error "Validation failed: $dir"
            failed=1
        fi
    done
    
    return $failed
}

# TFLint checks
check_lint() {
    print_status "Running TFLint..."
    
    # Initialize tflint
    if ! tflint --init > /dev/null 2>&1; then
        print_error "Failed to initialize TFLint"
        return 1
    fi
    
    local failed=0
    
    # Lint module
    echo ""
    print_status "Linting: modules/managed-redis"
    if tflint --chdir=modules/managed-redis/ --config=../../.tflint.hcl; then
        print_success "TFLint passed: modules/managed-redis"
    else
        print_error "TFLint failed: modules/managed-redis"
        failed=1
    fi
    
    # Lint examples
    for example in examples/*/; do
        echo ""
        print_status "Linting: $example"
        
        # Use local .tflint.hcl if it exists, otherwise use root config
        if [ -f "$example/.tflint.hcl" ]; then
            print_warning "Using local .tflint.hcl"
            if tflint --chdir="$example"; then
                print_success "TFLint passed: $example"
            else
                print_error "TFLint failed: $example"
                failed=1
            fi
        else
            if tflint --chdir="$example" --config=../../.tflint.hcl; then
                print_success "TFLint passed: $example"
            else
                print_error "TFLint failed: $example"
                failed=1
            fi
        fi
    done
    
    return $failed
}

# Security scan (if tfsec is installed)
check_security() {
    if ! command_exists tfsec; then
        print_warning "tfsec not installed, skipping security scan"
        print_warning "Install with: brew install tfsec"
        return 0
    fi
    
    print_status "Running security scan with tfsec..."
    
    if tfsec . --soft-fail; then
        print_success "Security scan completed"
        return 0
    else
        print_warning "Security issues found (soft-fail enabled)"
        return 0
    fi
}

# Run GitHub Actions locally (if act is installed)
run_with_act() {
    local job=$1
    
    if ! command_exists act; then
        print_warning "act not installed"
        echo "Install with: brew install act"
        echo "Then run: act -j $job"
        return 0
    fi
    
    print_status "Running GitHub Actions job: $job"
    act -j "$job"
}

# Main execution
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  Local Testing for Azure Managed Redis Terraform Repository   ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    local test_type=${1:-all}
    local exit_code=0
    
    case $test_type in
        install|setup)
            print_status "Checking and installing prerequisites..."
            check_prerequisites
            echo ""
            print_success "Setup complete! You can now run tests."
            echo ""
            echo "Try: $0 all"
            ;;
        format|fmt)
            check_prerequisites
            check_format || exit_code=1
            ;;
        validate)
            check_prerequisites
            check_validate || exit_code=1
            ;;
        lint)
            check_prerequisites
            check_lint || exit_code=1
            ;;
        security)
            check_security || exit_code=1
            ;;
        act)
            run_with_act "${2:-lint}" || exit_code=1
            ;;
        all)
            check_prerequisites
            echo ""
            check_format || exit_code=1
            echo ""
            check_validate || exit_code=1
            echo ""
            check_lint || exit_code=1
            echo ""
            check_security || exit_code=1
            ;;
        *)
            echo "Usage: $0 [install|format|validate|lint|security|act|all]"
            echo ""
            echo "Setup:"
            echo "  install    - Check and install required tools (terraform, tflint)"
            echo ""
            echo "Testing Options:"
            echo "  format     - Check Terraform formatting"
            echo "  validate   - Run Terraform validation"
            echo "  lint       - Run TFLint checks"
            echo "  security   - Run security scan with tfsec (optional)"
            echo "  act [job]  - Run GitHub Actions locally with act (optional)"
            echo "  all        - Run all checks (default)"
            echo ""
            echo "Examples:"
            echo "  $0 install            # Install missing tools"
            echo "  $0                    # Run all checks"
            echo "  $0 lint               # Run only TFLint"
            echo "  $0 act lint           # Run lint job with GitHub Actions locally"
            exit 1
            ;;
    esac
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        print_success "All checks passed! 🎉"
        echo ""
        echo "You can safely commit and push your changes."
    else
        print_error "Some checks failed! ❌"
        echo ""
        echo "Please fix the issues above before committing."
    fi
    echo ""
    
    exit $exit_code
}

# Run main function
main "$@"

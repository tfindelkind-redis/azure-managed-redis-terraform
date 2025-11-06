#!/usr/bin/env bash
#
# Pre-Commit Validation Script
# Runs all CI checks locally before committing
#
# This script mirrors the GitHub Actions CI workflow to catch issues early.
# Run this before committing to ensure all checks will pass in CI.
#
# Usage:
#   ./scripts/validate-pre-commit.sh              # Run all checks
#   ./scripts/validate-pre-commit.sh --fast       # Skip slower checks
#   ./scripts/validate-pre-commit.sh --help       # Show help

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Configuration
TF_VERSION="1.7.5"
TFLINT_VERSION="v0.59.1"
FAST_MODE=false
VERBOSE=false

# Directories to validate
VALIDATE_DIRS=(
    "modules/managed-redis"
    "examples/simple"
    "examples/with-modules"
    "examples/high-availability"
    "examples/geo-replication"
    "examples/clusterless-with-persistence"
    "examples/enterprise-security"
)

# Example directories
EXAMPLE_DIRS=(
    "simple"
    "with-modules"
    "high-availability"
    "geo-replication"
    "clusterless-with-persistence"
    "enterprise-security"
)

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
SKIPPED_CHECKS=0

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Helper Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

print_header() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() {
    echo -e "${BLUE}▸${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED_CHECKS++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED_CHECKS++))
}

print_skip() {
    echo -e "${YELLOW}⊘${NC} $1"
    ((SKIPPED_CHECKS++))
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

show_help() {
    cat << EOF
Pre-Commit Validation Script

This script runs all CI checks locally before committing to catch issues early.

Usage:
  ./scripts/validate-pre-commit.sh [OPTIONS]

Options:
  --fast          Skip slower checks (security scan, provider compatibility)
  --verbose       Show detailed output from commands
  --help          Show this help message

Examples:
  ./scripts/validate-pre-commit.sh              # Run all checks
  ./scripts/validate-pre-commit.sh --fast       # Quick validation
  ./scripts/validate-pre-commit.sh --verbose    # Show detailed output

Checks performed:
  1. Tool availability (terraform, tflint, terraform-docs)
  2. Terraform format check (all directories)
  3. Terraform initialization (all directories)
  4. Terraform validation (all directories)
  5. TFLint checks (module and examples)
  6. Documentation generation check
  7. Security scan with tfsec (unless --fast)
  8. Provider compatibility test (unless --fast)

Exit codes:
  0 - All checks passed
  1 - One or more checks failed
EOF
}

check_tool() {
    local tool=$1
    local install_url=$2
    
    if command -v "$tool" &> /dev/null; then
        local version=$("$tool" --version 2>&1 | head -n 1)
        print_success "$tool is installed: $version"
        return 0
    else
        print_error "$tool is not installed"
        print_info "Install from: $install_url"
        return 1
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Validation Functions
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_prerequisites() {
    print_header "Checking Prerequisites"
    ((TOTAL_CHECKS+=3))
    
    local tools_ok=true
    
    check_tool "terraform" "https://www.terraform.io/downloads" || tools_ok=false
    check_tool "tflint" "https://github.com/terraform-linters/tflint" || tools_ok=false
    check_tool "terraform-docs" "https://terraform-docs.io/user-guide/installation/" || tools_ok=false
    
    if [ "$tools_ok" = false ]; then
        print_error "Missing required tools. Please install them before continuing."
        return 1
    fi
    
    return 0
}

validate_terraform_format() {
    print_header "Terraform Format Check"
    
    local format_ok=true
    
    for dir in "${VALIDATE_DIRS[@]}"; do
        ((TOTAL_CHECKS++))
        print_step "Checking format in $dir"
        
        cd "$REPO_ROOT/$dir"
        
        if [ "$VERBOSE" = true ]; then
            if terraform fmt -check -recursive -diff; then
                print_success "$dir: Format check passed"
            else
                print_error "$dir: Format check failed"
                format_ok=false
            fi
        else
            if terraform fmt -check -recursive -diff > /dev/null 2>&1; then
                print_success "$dir: Format check passed"
            else
                print_error "$dir: Format check failed (run 'terraform fmt -recursive' to fix)"
                format_ok=false
            fi
        fi
    done
    
    if [ "$format_ok" = false ]; then
        print_info "Run 'terraform fmt -recursive' in the repository root to auto-fix formatting"
        return 1
    fi
    
    return 0
}

validate_terraform_init() {
    print_header "Terraform Initialization"
    
    local init_ok=true
    
    for dir in "${VALIDATE_DIRS[@]}"; do
        ((TOTAL_CHECKS++))
        print_step "Initializing $dir"
        
        cd "$REPO_ROOT/$dir"
        
        if [ "$VERBOSE" = true ]; then
            if terraform init -backend=false; then
                print_success "$dir: Initialization successful"
            else
                print_error "$dir: Initialization failed"
                init_ok=false
            fi
        else
            if terraform init -backend=false > /dev/null 2>&1; then
                print_success "$dir: Initialization successful"
            else
                print_error "$dir: Initialization failed"
                init_ok=false
            fi
        fi
    done
    
    [ "$init_ok" = true ] && return 0 || return 1
}

validate_terraform_validate() {
    print_header "Terraform Validation"
    
    local validate_ok=true
    
    for dir in "${VALIDATE_DIRS[@]}"; do
        ((TOTAL_CHECKS++))
        print_step "Validating $dir"
        
        cd "$REPO_ROOT/$dir"
        
        if [ "$VERBOSE" = true ]; then
            if terraform validate; then
                print_success "$dir: Validation passed"
            else
                print_error "$dir: Validation failed"
                validate_ok=false
            fi
        else
            if terraform validate > /dev/null 2>&1; then
                print_success "$dir: Validation passed"
            else
                print_error "$dir: Validation failed"
                validate_ok=false
            fi
        fi
    done
    
    [ "$validate_ok" = true ] && return 0 || return 1
}

validate_tflint() {
    print_header "TFLint Checks"
    
    local lint_ok=true
    
    cd "$REPO_ROOT"
    
    # Initialize TFLint
    ((TOTAL_CHECKS++))
    print_step "Initializing TFLint"
    if [ "$VERBOSE" = true ]; then
        if tflint --init; then
            print_success "TFLint initialized"
        else
            print_error "TFLint initialization failed"
            return 1
        fi
    else
        if tflint --init > /dev/null 2>&1; then
            print_success "TFLint initialized"
        else
            print_error "TFLint initialization failed"
            return 1
        fi
    fi
    
    # Lint module
    ((TOTAL_CHECKS++))
    print_step "Linting module: modules/managed-redis"
    if [ "$VERBOSE" = true ]; then
        if tflint --chdir=modules/managed-redis/ --config="$REPO_ROOT/.tflint.hcl"; then
            print_success "Module lint passed"
        else
            print_error "Module lint failed"
            lint_ok=false
        fi
    else
        if tflint --chdir=modules/managed-redis/ --config="$REPO_ROOT/.tflint.hcl" > /dev/null 2>&1; then
            print_success "Module lint passed"
        else
            print_error "Module lint failed"
            lint_ok=false
        fi
    fi
    
    # Lint examples
    for example_dir in examples/*/; do
        ((TOTAL_CHECKS++))
        example_name=$(basename "$example_dir")
        print_step "Linting example: $example_name"
        
        if [ -f "$example_dir/.tflint.hcl" ]; then
            config_option=""
        else
            config_option="--config=$REPO_ROOT/.tflint.hcl"
        fi
        
        if [ "$VERBOSE" = true ]; then
            if tflint --chdir="$example_dir" $config_option; then
                print_success "$example_name: Lint passed"
            else
                print_error "$example_name: Lint failed"
                lint_ok=false
            fi
        else
            if tflint --chdir="$example_dir" $config_option > /dev/null 2>&1; then
                print_success "$example_name: Lint passed"
            else
                print_error "$example_name: Lint failed"
                lint_ok=false
            fi
        fi
    done
    
    [ "$lint_ok" = true ] && return 0 || return 1
}

validate_documentation() {
    print_header "Documentation Check"
    
    ((TOTAL_CHECKS++))
    
    cd "$REPO_ROOT"
    
    print_step "Generating documentation for modules/managed-redis"
    
    if [ "$VERBOSE" = true ]; then
        terraform-docs markdown table --output-file README.md --output-mode inject modules/managed-redis
    else
        terraform-docs markdown table --output-file README.md --output-mode inject modules/managed-redis > /dev/null 2>&1
    fi
    
    print_step "Checking if documentation is up to date"
    
    if git diff --exit-code modules/managed-redis/README.md > /dev/null 2>&1; then
        print_success "Module documentation is up to date"
        return 0
    else
        print_error "Module documentation is not up to date"
        print_info "Run 'terraform-docs markdown table --output-file README.md --output-mode inject modules/managed-redis' and commit the changes"
        
        # Restore the file
        git checkout modules/managed-redis/README.md 2>/dev/null || true
        return 1
    fi
}

validate_security() {
    if [ "$FAST_MODE" = true ]; then
        print_header "Security Scan"
        print_skip "Skipped in fast mode"
        return 0
    fi
    
    print_header "Security Scan with tfsec"
    
    ((TOTAL_CHECKS++))
    
    if ! command -v tfsec &> /dev/null; then
        print_skip "tfsec not installed (optional check)"
        print_info "Install from: https://aquasecurity.github.io/tfsec/"
        return 0
    fi
    
    cd "$REPO_ROOT"
    
    print_step "Running tfsec security scan"
    
    if [ "$VERBOSE" = true ]; then
        if tfsec . --soft-fail; then
            print_success "Security scan completed (warnings allowed)"
        else
            print_error "Security scan failed"
            return 1
        fi
    else
        if tfsec . --soft-fail > /dev/null 2>&1; then
            print_success "Security scan completed (warnings allowed)"
        else
            print_error "Security scan failed"
            return 1
        fi
    fi
    
    return 0
}

validate_provider_compatibility() {
    if [ "$FAST_MODE" = true ]; then
        print_header "Provider Compatibility"
        print_skip "Skipped in fast mode"
        return 0
    fi
    
    print_header "Provider Compatibility Test"
    
    print_info "Testing latest provider versions only (full matrix runs in CI)"
    
    ((TOTAL_CHECKS++))
    
    cd "$REPO_ROOT/modules/managed-redis"
    
    # Save original versions
    cp versions.tf versions.tf.bak
    
    print_step "Testing with current provider versions"
    
    if [ "$VERBOSE" = true ]; then
        if terraform init && terraform validate; then
            print_success "Provider compatibility check passed"
            rm versions.tf.bak
            return 0
        else
            print_error "Provider compatibility check failed"
            mv versions.tf.bak versions.tf
            return 1
        fi
    else
        if terraform init > /dev/null 2>&1 && terraform validate > /dev/null 2>&1; then
            print_success "Provider compatibility check passed"
            rm versions.tf.bak
            return 0
        else
            print_error "Provider compatibility check failed"
            mv versions.tf.bak versions.tf
            return 1
        fi
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main Execution
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fast)
            FAST_MODE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Print banner
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║           Pre-Commit Validation - CI Checks                     ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Repository:${NC} $(basename "$REPO_ROOT")"
echo -e "${BLUE}Mode:${NC} $([ "$FAST_MODE" = true ] && echo "Fast (skipping slow checks)" || echo "Full validation")"
echo -e "${BLUE}Verbose:${NC} $VERBOSE"
echo ""

# Run all checks
ALL_PASSED=true

check_prerequisites || ALL_PASSED=false
validate_terraform_format || ALL_PASSED=false
validate_terraform_init || ALL_PASSED=false
validate_terraform_validate || ALL_PASSED=false
validate_tflint || ALL_PASSED=false
validate_documentation || ALL_PASSED=false
validate_security || ALL_PASSED=false
validate_provider_compatibility || ALL_PASSED=false

# Print summary
print_header "Validation Summary"

echo ""
echo -e "${BOLD}Total checks:${NC}    $TOTAL_CHECKS"
echo -e "${GREEN}Passed:${NC}         $PASSED_CHECKS"
echo -e "${RED}Failed:${NC}         $FAILED_CHECKS"
echo -e "${YELLOW}Skipped:${NC}        $SKIPPED_CHECKS"
echo ""

if [ "$ALL_PASSED" = true ]; then
    echo -e "${GREEN}${BOLD}✓ All checks passed! Ready to commit.${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}${BOLD}✗ Some checks failed. Please fix the issues before committing.${NC}"
    echo ""
    echo -e "${YELLOW}Quick fixes:${NC}"
    echo -e "  • Format issues:        ${BLUE}terraform fmt -recursive${NC}"
    echo -e "  • Documentation:        ${BLUE}terraform-docs markdown table --output-file README.md --output-mode inject modules/managed-redis${NC}"
    echo -e "  • Re-run validation:    ${BLUE}./scripts/validate-pre-commit.sh${NC}"
    echo ""
    exit 1
fi

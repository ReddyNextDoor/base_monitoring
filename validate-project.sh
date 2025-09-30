#!/bin/bash

# Project Validation Script
# Validates the complete enhanced Netdata monitoring project

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
CHECKS_TOTAL=0
CHECKS_PASSED=0
CHECKS_FAILED=0

# Check functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
    ((CHECKS_TOTAL++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((CHECKS_FAILED++))
    ((CHECKS_TOTAL++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((CHECKS_TOTAL++))
}

echo -e "${BLUE}🔍 Enhanced Netdata Monitoring Project Validation${NC}"
echo "=================================================="
echo ""

# Check 1: Required files exist
echo "📁 Checking project files..."
required_files=(
    "setup.sh"
    "test_dashboard.sh" 
    "cleanup.sh"
    "monitoring-config.sh"
    "test-suite.sh"
    "docker-setup.sh"
    "docker-compose.yml"
    "prometheus.yml"
    "Makefile"
    "README.md"
    "enhancements.md"
    "requirements.md"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        check_pass "File exists: $file"
    else
        check_fail "Missing file: $file"
    fi
done

# Check 2: Script permissions
echo ""
echo "🔐 Checking script permissions..."
script_files=(
    "setup.sh"
    "test_dashboard.sh"
    "cleanup.sh" 
    "monitoring-config.sh"
    "test-suite.sh"
    "docker-setup.sh"
    "validate-project.sh"
)

for script in "${script_files[@]}"; do
    if [[ -x "$script" ]]; then
        check_pass "Executable: $script"
    else
        check_fail "Not executable: $script"
    fi
done

# Check 3: Script syntax validation
echo ""
echo "📝 Checking script syntax..."
for script in "${script_files[@]}"; do
    if bash -n "$script" 2>/dev/null; then
        check_pass "Syntax valid: $script"
    else
        check_fail "Syntax error: $script"
    fi
done

# Check 4: Docker configuration validation
echo ""
echo "🐳 Checking Docker configuration..."
if command -v docker &> /dev/null; then
    if docker-compose config &> /dev/null; then
        check_pass "Docker Compose configuration is valid"
    else
        check_fail "Docker Compose configuration has errors"
    fi
else
    check_warn "Docker not installed (optional for native deployment)"
fi

# Check 5: Makefile validation
echo ""
echo "🔨 Checking Makefile..."
if command -v make &> /dev/null; then
    if make -n help &> /dev/null; then
        check_pass "Makefile syntax is valid"
    else
        check_fail "Makefile has syntax errors"
    fi
    
    # Check for required targets
    required_targets=(
        "help"
        "install"
        "test"
        "clean"
        "all"
    )
    
    for target in "${required_targets[@]}"; do
        if make -n "$target" &> /dev/null; then
            check_pass "Makefile target exists: $target"
        else
            check_fail "Makefile target missing: $target"
        fi
    done
else
    check_warn "Make not installed (optional)"
fi

# Check 6: Documentation validation
echo ""
echo "📚 Checking documentation..."
doc_files=(
    "README.md"
    "enhancements.md"
    "requirements.md"
)

for doc in "${doc_files[@]}"; do
    if [[ -s "$doc" ]]; then
        check_pass "Documentation exists and not empty: $doc"
    else
        check_fail "Documentation missing or empty: $doc"
    fi
done

# Check 7: Configuration files
echo ""
echo "⚙️ Checking configuration files..."
config_files=(
    "docker-compose.yml"
    "prometheus.yml"
)

for config in "${config_files[@]}"; do
    if [[ -s "$config" ]]; then
        check_pass "Configuration file exists: $config"
    else
        check_fail "Configuration file missing: $config"
    fi
done

# Check 8: Project structure validation
echo ""
echo "🏗️ Checking project structure..."

# Check for proper shebang lines
for script in "${script_files[@]}"; do
    if head -1 "$script" | grep -q "#!/bin/bash"; then
        check_pass "Proper shebang: $script"
    else
        check_fail "Missing or incorrect shebang: $script"
    fi
done

# Check for error handling
for script in "${script_files[@]}"; do
    if grep -q "set -euo pipefail" "$script"; then
        check_pass "Error handling enabled: $script"
    else
        check_warn "No strict error handling: $script"
    fi
done

# Check 9: Feature completeness
echo ""
echo "🎯 Checking feature completeness..."

# Check for logging functions
for script in "${script_files[@]}"; do
    if grep -q "log()" "$script"; then
        check_pass "Logging functions present: $script"
    else
        check_warn "No logging functions: $script"
    fi
done

# Check for help/usage functions
for script in "${script_files[@]}"; do
    if grep -q "usage()" "$script"; then
        check_pass "Usage function present: $script"
    else
        check_warn "No usage function: $script"
    fi
done

# Check 10: Enhancement validation
echo ""
echo "🚀 Checking enhancements..."

# Check if enhancements are documented
if grep -q "Multi-distribution support" enhancements.md; then
    check_pass "Multi-distribution support documented"
else
    check_fail "Multi-distribution support not documented"
fi

if grep -q "Docker deployment" enhancements.md; then
    check_pass "Docker deployment documented"
else
    check_fail "Docker deployment not documented"
fi

if grep -q "Comprehensive testing" enhancements.md; then
    check_pass "Testing framework documented"
else
    check_fail "Testing framework not documented"
fi

# Final summary
echo ""
echo "📊 Validation Summary"
echo "===================="
echo -e "Total checks: ${BLUE}$CHECKS_TOTAL${NC}"
echo -e "Passed: ${GREEN}$CHECKS_PASSED${NC}"
echo -e "Failed: ${RED}$CHECKS_FAILED${NC}"
echo -e "Success rate: ${BLUE}$(( CHECKS_PASSED * 100 / CHECKS_TOTAL ))%${NC}"

echo ""
if [[ $CHECKS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}🎉 Project validation completed successfully!${NC}"
    echo -e "${GREEN}✅ All components are ready for deployment${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run 'make all' for complete setup"
    echo "2. Run 'make docker-setup' for Docker deployment"
    echo "3. Run 'make test-full' for comprehensive testing"
    echo "4. Access dashboard at http://localhost:19999"
    exit 0
else
    echo -e "${RED}❌ Project validation found issues${NC}"
    echo -e "${YELLOW}Please fix the failed checks before deployment${NC}"
    exit 1
fi
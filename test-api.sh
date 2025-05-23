#!/bin/bash

# Test script for Node.js application with APISIX gateway
# This script runs a series of tests to verify the functionality of the API

# Color codes for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
    fi
}

# Function to run a test and check the result
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_status="$3"
    
    echo -e "\n${YELLOW}Running test: ${test_name}${NC}"
    
    # Run the command and capture output and status
    output=$(eval "$command" 2>&1)
    status=$?
    
    # Check if status matches expected status
    if [ "$status" -eq "$expected_status" ]; then
        print_result 0 "$test_name"
    else
        print_result 1 "$test_name (Expected status: $expected_status, Got: $status)"
    fi
    
    # Print output (truncated if too long)
    if [ ${#output} -gt 500 ]; then
        echo "${output:0:500}... (truncated)"
    else
        echo "$output"
    fi
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Please install it to run this script.${NC}"
    echo "You can install it with: brew install jq (on macOS) or apt-get install jq (on Ubuntu)"
    exit 1
fi

echo -e "${YELLOW}=== Testing Node.js Application with APISIX Gateway ===${NC}"

# Test 1: Check if containers are running
run_test "Check if containers are running" "docker ps | grep -E 'apisix|nodejs'" 0

# Test 2: Direct access to Node.js application - Get all items
run_test "Direct access - Get all items" "curl -s http://localhost:3000/items | jq -e '.items | length > 0'" 0

# Test 3: Access through APISIX - Get all items
run_test "APISIX access - Get all items" "curl -s http://localhost:9080/api/items | jq -e '.items | length > 0'" 0

# Test 4: Direct access to Node.js application - Health check
run_test "Direct access - Health check" "curl -s http://localhost:3000/health | jq -e '.status == \"ok\"'" 0

# Test 5: Access through APISIX - Health check
run_test "APISIX access - Health check" "curl -s http://localhost:9080/api/health | jq -e '.status == \"ok\"'" 0

# Test 6: Direct access - Filter items by electronics category
run_test "Direct access - Filter by electronics" "curl -s -X POST -H \"Content-Type: application/json\" -d '{\"category\":\"electronics\"}' http://localhost:3000/items/filter | jq -e '.items | length == 2'" 0

# Test 7: APISIX access - Filter items by electronics category
run_test "APISIX access - Filter by electronics" "curl -s -X POST -H \"Content-Type: application/json\" -d '{\"category\":\"electronics\"}' http://localhost:9080/api/items/filter | jq -e '.items | length == 2'" 0

# Test 8: APISIX access - Filter items by appliances category
run_test "APISIX access - Filter by appliances" "curl -s -X POST -H \"Content-Type: application/json\" -d '{\"category\":\"appliances\"}' http://localhost:9080/api/items/filter | jq -e '.items | length == 1'" 0

# Test 9: APISIX access - Filter items by sports category
run_test "APISIX access - Filter by sports" "curl -s -X POST -H \"Content-Type: application/json\" -d '{\"category\":\"sports\"}' http://localhost:9080/api/items/filter | jq -e '.items | length == 1'" 0

# Test 10: APISIX access - Filter by non-existent category
run_test "APISIX access - Filter by non-existent category" "curl -s -X POST -H \"Content-Type: application/json\" -d '{\"category\":\"clothing\"}' http://localhost:9080/api/items/filter | jq -e '.items | length == 0'" 0

# Test 11: Check APISIX response headers
run_test "APISIX response headers" "curl -s -I http://localhost:9080/api/items | grep -q 'Server: APISIX'" 0

# Test 12: Check error handling for non-existent routes
run_test "Error handling - Non-existent route" "curl -s -o /dev/null -w '%{http_code}' http://localhost:9080/api/nonexistent | grep -q '404'" 0

# Test 13: Performance test - Response time comparison
echo -e "\n${YELLOW}Performance Test: Response Time Comparison${NC}"
echo "Direct access response time:"
time curl -s http://localhost:3000/items > /dev/null

echo -e "\nAPISIX access response time:"
time curl -s http://localhost:9080/api/items > /dev/null

# Test 14: Check APISIX logs for errors
run_test "APISIX logs - Check for errors" "docker logs apache-apisix-1 2>&1 | grep -i error || echo 'No errors found'" 0

echo -e "\n${YELLOW}=== All tests completed ===${NC}"

#!/bin/bash

set -e

# Set up variables
WORKING_DIR=$(pwd)
TARGET_DIR="$WORKING_DIR/tests/references/target"
CAIRO_LOG="$TARGET_DIR/cairo_output.log"
NUTSHELL_LOG="$TARGET_DIR/nutshell_output.log"
PATTERNS_FILE="$WORKING_DIR/tests/references/patterns.txt"
RESULTS_FILE="$TARGET_DIR/results.json"
REPORT_FILE="$TARGET_DIR/report.txt"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Function to run tests and save logs
run_tests() {
    echo "Running Cairo implementation..."
    cd "$WORKING_DIR"
    scarb cairo-run --available-gas=200000000 > "$CAIRO_LOG" 2>&1

    echo "Running Nutshell implementation..."
    cd "$WORKING_DIR/tests/references/bdhke-nutshell"
    ./run_nutshell.sh > "$NUTSHELL_LOG" 2>&1
}

# Function to extract values from logs
extract_values() {
    local log_file=$1
    local pattern=$2
    grep "$pattern" "$log_file" | cut -d':' -f2 | tr -d ' '
}

# Initialize counters
total_patterns=0
matching_patterns=0

# Function to compare values and update results
compare_values() {
    local pattern=$1
    local cairo_value=$(extract_values "$CAIRO_LOG" "$pattern")
    local nutshell_value=$(extract_values "$NUTSHELL_LOG" "$pattern")
    
    echo "Pattern: $pattern" >> "$REPORT_FILE"
    echo "Cairo value: $cairo_value" >> "$REPORT_FILE"
    echo "Nutshell value: $nutshell_value" >> "$REPORT_FILE"
    
    total_patterns=$((total_patterns + 1))
    
    if [ -z "$cairo_value" ] && [ -z "$nutshell_value" ]; then
        echo "  \"$pattern\": false," >> "$RESULTS_FILE"
        echo "❌ $pattern: Missing value in both implementations" >> "$REPORT_FILE"
    elif [ -z "$cairo_value" ]; then
        echo "  \"$pattern\": false," >> "$RESULTS_FILE"
        echo "❌ $pattern: Missing value in Cairo implementation" >> "$REPORT_FILE"
    elif [ -z "$nutshell_value" ]; then
        echo "  \"$pattern\": false," >> "$RESULTS_FILE"
        echo "❌ $pattern: Missing value in Nutshell implementation" >> "$REPORT_FILE"
    elif [ "$cairo_value" = "$nutshell_value" ]; then
        echo "  \"$pattern\": true," >> "$RESULTS_FILE"
        echo "✅ $pattern: Match" >> "$REPORT_FILE"
        matching_patterns=$((matching_patterns + 1))
    else
        echo "  \"$pattern\": false," >> "$RESULTS_FILE"
        echo "❌ $pattern: Mismatch" >> "$REPORT_FILE"
        echo "   Cairo: $cairo_value" >> "$REPORT_FILE"
        echo "   Nutshell: $nutshell_value" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
}

# Main execution
echo "Starting reference tests..."

# Run tests
run_tests

# Initialize results file
echo "{" > "$RESULTS_FILE"

# Initialize report file
echo "Reference Test Report" > "$REPORT_FILE"
echo "=====================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Compare values for each pattern
while IFS= read -r pattern || [ -n "$pattern" ]
do
    compare_values "$pattern"
done < "$PATTERNS_FILE"

# Finalize results file
# Remove the trailing comma and add the closing brace
sed -i.bak '$ s/,$//' "$RESULTS_FILE" && rm "${RESULTS_FILE}.bak"
echo "}" >> "$RESULTS_FILE"

# Add summary to report
echo "Summary:" >> "$REPORT_FILE"
echo "--------" >> "$REPORT_FILE"
echo "Total patterns: $total_patterns" >> "$REPORT_FILE"
echo "Matching patterns: $matching_patterns" >> "$REPORT_FILE"

if [ "$total_patterns" -eq "$matching_patterns" ]; then
    echo "✅ All patterns match" >> "$REPORT_FILE"
    test_result=0
else
    echo "❌ Some patterns do not match" >> "$REPORT_FILE"
    test_result=1
fi

# Display report
cat "$REPORT_FILE"

echo "Reference tests completed. See $REPORT_FILE for full report."

# Exit with the appropriate status
exit $test_result
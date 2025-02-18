#!/bin/bash

# Check if a log file is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

# Define the log file and output files
LOG_FILE="$1"
OUTPUT_FILE="bdr_issues.log"
METRICS_FILE="bdr_metrics.log"

# Clear the output files if they exist
> "$OUTPUT_FILE" || { echo "Error: Cannot write to $OUTPUT_FILE"; exit 1; }
> "$METRICS_FILE" || { echo "Error: Cannot write to $METRICS_FILE"; exit 1; }

# Define the patterns to search for
PATTERNS=(
    "BDR"
    "could not connect to the BDR node"
    "connection to BDR node timed out"
    "BDR version mismatch detected"
    "failed to apply BDR upgrade"
    "conflict detected during replication"
    "invalid BDR configuration"
    "out of worker processes"
    "could not create replication slot"
    "logical decoding error"
    "WAL sender/receiver timeout"
)

# Create a single pattern string for grep
PATTERN_STRING=$(printf "|%s" "${PATTERNS[@]}")
PATTERN_STRING=${PATTERN_STRING:1}  # Remove the leading '|'

# Function to gather additional metrics
gather_metrics() {
    local log_file=$1
    local issue=$2

    echo "Gathering metrics for issue: $issue in $log_file" >> "$METRICS_FILE"
    # Example: Gather the last 10 lines before and after the issue
    grep -B 10 -A 10 -i "$issue" "$log_file" >> "$METRICS_FILE"
    echo "----------------------------------------" >> "$METRICS_FILE"
}

# Function to count occurrences of each pattern
count_occurrences() {
    local log_file=$1
    local pattern=$2
    grep -ci "$pattern" "$log_file"
}

# Check if the log file exists
if [[ -f "$LOG_FILE" ]]; then
    echo "Processing $LOG_FILE..."
    # Search for patterns and gather metrics if issues are found
    grep -Ei "$PATTERN_STRING" "$LOG_FILE" >> "$OUTPUT_FILE"
    for PATTERN in "${PATTERNS[@]}"; do
        if grep -qi "$PATTERN" "$LOG_FILE"; then
            gather_metrics "$LOG_FILE" "$PATTERN"
            COUNT=$(count_occurrences "$LOG_FILE" "$PATTERN")
            echo "Issue: $PATTERN, Count: $COUNT" >> "$METRICS_FILE"
        fi
    done
else
    echo "Log file $LOG_FILE not found"
    exit 1
fi

echo "BDR-related log entries have been saved to $OUTPUT_FILE"
echo "Additional metrics have been saved to $METRICS_FILE"
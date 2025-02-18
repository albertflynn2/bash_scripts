#!/bin/bash

# Check if the log file is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

LOG_FILE="$1"
CHUNK_SIZE=100000
CHUNK_PREFIX="chunk_"
RESULT_DIR="results"
JSON_FILE="${LOG_FILE%.csv}.json"

# Create the results directory if it doesn't exist
mkdir -p "$RESULT_DIR"

# Clear the results directory
rm -f "$RESULT_DIR"/*

# Function to convert CSV to JSON
convert_csv_to_json() {
    local csv_file=$1
    local json_file=$2

    # Use jq to convert CSV to JSON
    jq -R -s -f csv_to_json.jq "$csv_file" > "$json_file"
}

# Function to run jq and grep/egrep commands and log results
run_grep_commands() {
    local file=$1

    declare -A logs=(
        ["memory"]="OutOfMemoryError|Heap usage:|real=[1-9]|Humongous Allocation"
        ["network"]="eth[0-9]:.*error|connection reset by peer|mcas\\.util\\.network:.*false|packet return time: [1-9][0-9]|unreachable"
        ["partitioned_operations"]="Partitioned operation.*took [1-9][0-9]{3,} ms|Partitioned operation|Terminating process"
        ["switches_connect_disconnect"]="mcas\\.platform\\.net.*Reconnect attempt|mcas\\.platform\\.net.*(Connected|Connection lost)"
        ["restart_reason"]="JVM crash|hs_err_pid|Fatal error:|Blocked thread|Shutdown initiated by Signal Handler"
        ["db_performance"]="slow query|mcas\\.db\\.usage:DB[1-4]\\.summary:.*(ins|upd).*ave\\([1-9][0-9][0-9]|\\? \\[.*\\([1-9][0-9][0-9]"
        ["mcas_sync"]="sync failure|mcas\\.db\\.pending|still executing|^Qs.*SwitchLog|^DB.*SwitchLog"
        ["direct_connect"]="Direct Connect latency|still waiting for \\[tx-completion\\]"
        ["congestion_control"]="congestion event|mcas.cc.trace"
        ["user_activity_audit_events"]="user login attempt|MCAS/Access"
        ["callback_timeout"]="callback.*has been waiting for"
        ["db_operations_replay"]="mcas.db.map.*db_operations_replay"
        ["db_transactions_waiting"]="still waiting for \\[tx-completion\\]"
        ["switch_restart"]="mcas.observability.*switch_restart"
        ["general_error_messages"]="error.message"
        ["timestamp_specific_searches"]="@timestamp\":\"2024-11-05T10:30:29"
        ["network_disconnects"]="network disconnecting idle connections"
        ["additional_command"]="FATAL ERROR| TPS=|signal|mcas.db.full.usage:.*\\?.*\\([0-9]{4}"
        ["disk_io"]="I/O error|disk read error|disk write error"
        ["cpu_usage"]="CPU usage: [8-9][0-9]%|CPU load average"
        ["application_errors"]="Exception|Error|Critical|Failed"
    )

    for log in "${!logs[@]}"; do
        log_file="$RESULT_DIR/${log}.log"
        echo "### ${log//_/ } ###" > "$log_file"
        
        # Use jq to parse JSON/NDJSON and grep for patterns
        jq -c '.' "$file" | egrep -i "${logs[$log]}" | jq '.' >> "$log_file"
        
        echo "Log entries for ${log//_/ } have been saved to $log_file"
    done
}

# Function to check specific timestamps
check_timestamps() {
    local file=$1
    local timestamp_file="$RESULT_DIR/timestamps.log"
    echo "### Timestamps Check ###" > "$timestamp_file"

    jq -c '.' "$file" | egrep -i 'cmt|bat|ser|snt' | jq '.' >> "$timestamp_file"
    echo "Timestamp entries have been saved to $timestamp_file"
}

# Function to handle errors in JSON/NDJSON parsing
handle_json_errors() {
    local file=$1
    local error_file="$RESULT_DIR/json_errors.log"
    echo "### JSON Parsing Errors ###" > "$error_file"

    jq -c '.' "$file" 2>> "$error_file"
    echo "JSON parsing errors have been saved to $error_file"
}

# Check if the file is CSV and convert to JSON if needed
if [[ "$LOG_FILE" == *.csv ]]; then
    echo "Converting CSV to JSON..."
    convert_csv_to_json "$LOG_FILE" "$JSON_FILE"
    LOG_FILE="$JSON_FILE"
fi

# Check if the log file needs to be split
if [ $(wc -l < "$LOG_FILE") -gt $CHUNK_SIZE ]; then
    echo "Splitting the log file into chunks..."
    split -l $CHUNK_SIZE "$LOG_FILE" "$CHUNK_PREFIX"
    for file in ${CHUNK_PREFIX}*; do
        run_grep_commands "$file"
        check_timestamps "$file"
        handle_json_errors "$file"
        rm "$file"  # Remove the chunk after processing
    done
else
    run_grep_commands "$LOG_FILE"
    check_timestamps "$LOG_FILE"
    handle_json_errors "$LOG_FILE"
fi

# Generate a detailed summary report
SUMMARY_FILE="$RESULT_DIR/summary_report.txt"
echo "### Detailed Summary Report ###" > "$SUMMARY_FILE"
for log in "${!logs[@]}"; do
    log_file="$RESULT_DIR/${log}.log"
    if [ -s "$log_file" ]; then
        echo "Category: ${log//_/ }" >> "$SUMMARY_FILE"
        echo "Number of entries: $(wc -l < "$log_file")" >> "$SUMMARY_FILE"
        echo "Sample entries:" >> "$SUMMARY_FILE"
        head -n 5 "$log_file" >> "$SUMMARY_FILE"
        echo "..." >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
    fi
done

echo "Log analysis completed. Detailed summary report generated at $SUMMARY_FILE"
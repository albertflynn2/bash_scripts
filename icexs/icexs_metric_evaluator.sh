#!/bin/bash

# Check if a log file is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

# Path to the log file
LOG_FILE=$1

# Output log file
OUTPUT_LOG="./icexs_metrics_evaluation.log"
> "$OUTPUT_LOG"  # Clear output log

# Temporary files to track status changes
UP_TEMP=$(mktemp)
DOWN_TEMP=$(mktemp)
UP_TO_DOWN_TEMP=$(mktemp)
DOWN_TO_UP_TEMP=$(mktemp)

# Function to parse and evaluate metrics using awk
evaluate_metrics() {
    local log_file=$1
    local output_log=$2

    awk '
    BEGIN {
        total_endpoints = 0;
        total_up = 0;
        total_down = 0;
        cumulative_in = 0;
        cumulative_out = 0;
        count_zero_queue = 0;
        count_zero_connection = 0;
    }

    # Function to process each line
    function process_line(line) {
        if (line ~ /(I|E)-[0-9]+-EP/) {
            split(line, sections, " ");
            endpoint = sections[2];
            status = sections[4];

            # Extract IN/OUT data flow
            match(sections[7], /IN\/OUT=\[([0-9]+)\/([0-9]+)\]/, dataflow);
            in_flow = dataflow[1];
            out_flow = dataflow[2];
            cumulative_in += in_flow;
            cumulative_out += out_flow;

            # Detect queue depth and connection count anomalies
            if (sections[6] ~ /Qd=\[0,0\]/) count_zero_queue++;
            if (sections[5] ~ /C=\[0\/0\]/) count_zero_connection++;

            # Track status and irregularities
            if (!(endpoint in endpoint_status)) {
                endpoint_status[endpoint] = status;
                total_endpoints++;
                if (status == "UP") {
                    total_up++;
                    up_endpoints[total_up] = line;
                    print line > "'"$UP_TEMP"'"
                } else if (status == "DOWN") {
                    total_down++;
                    down_endpoints[total_down] = line;
                    print line > "'"$DOWN_TEMP"'"
                }
            } else {
                if (endpoint_status[endpoint] == "UP" && status == "DOWN") {
                    down_count[endpoint]++;
                    endpoint_status[endpoint] = status;
                } else if (endpoint_status[endpoint] == "DOWN" && status == "UP") {
                    up_count[endpoint]++;
                    endpoint_status[endpoint] = status;
                }
            }
        }
    }

    {
        process_line($0);
    }

    END {
        # Print header information
        print "Evaluation Date: " strftime("%Y-%m-%d %H:%M:%S") > "'"$OUTPUT_LOG"'";
        print "Log File: " "'"$log_file"'" > "'"$OUTPUT_LOG"'";
        print "Total Endpoints: " total_endpoints > "'"$OUTPUT_LOG"'";
        print "Endpoints UP: " total_up > "'"$OUTPUT_LOG"'";
        print "Endpoints DOWN: " total_down > "'"$OUTPUT_LOG"'";
        
        # Print Data Flow Analysis
        print "-----------------------------------" > "'"$OUTPUT_LOG"'";
        print "Data Flow Analysis:" > "'"$OUTPUT_LOG"'";
        print "Cumulative IN: " cumulative_in > "'"$OUTPUT_LOG"'";
        print "Cumulative OUT: " cumulative_out > "'"$OUTPUT_LOG"'";
        print "Average IN: " (total_endpoints > 0 ? cumulative_in / total_endpoints : 0) > "'"$OUTPUT_LOG"'";
        print "Average OUT: " (total_endpoints > 0 ? cumulative_out / total_endpoints : 0) > "'"$OUTPUT_LOG"'";

        # Display queue and connection irregularities
        print "-----------------------------------" > "'"$OUTPUT_LOG"'";
        print "Queue Depth and Connection Irregularities:" > "'"$OUTPUT_LOG"'";
        print "Endpoints with Qd=[0,0]: " count_zero_queue > "'"$OUTPUT_LOG"'";
        print "Endpoints with C=[0/0]: " count_zero_connection > "'"$OUTPUT_LOG"'";

        # Display UP endpoints
        print "-----------------------------------" > "'"$OUTPUT_LOG"'";
        print "UP Endpoints:" > "'"$OUTPUT_LOG"'";
        for (i = 1; i <= total_up; i++) {
            print up_endpoints[i] > "'"$OUTPUT_LOG"'";
        }

        # Display DOWN endpoints
        print "-----------------------------------" > "'"$OUTPUT_LOG"'";
        print "DOWN Endpoints:" > "'"$OUTPUT_LOG"'";
        for (i = 1; i <= total_down; i++) {
            print down_endpoints[i] > "'"$OUTPUT_LOG"'";
        }

        # Display summary of status changes
        print "-----------------------------------" > "'"$OUTPUT_LOG"'";
        print "Endpoint Status Changes:" > "'"$OUTPUT_LOG"'";
        for (endpoint in down_count) {
            print endpoint " went DOWN " down_count[endpoint] " times" > "'"$OUTPUT_LOG"'";
        }
        for (endpoint in up_count) {
            print endpoint " went UP " up_count[endpoint] " times" > "'"$OUTPUT_LOG"'";
        }
    }
    ' "$log_file"

    # Identify endpoints that transitioned from UP to DOWN
    awk 'NR==FNR{a[$0];next} !($0 in a)' "$UP_TEMP" "$DOWN_TEMP" > "$UP_TO_DOWN_TEMP"

    # Identify endpoints that transitioned from DOWN to UP
    awk 'NR==FNR{a[$0];next} !($0 in a)' "$DOWN_TEMP" "$UP_TEMP" > "$DOWN_TO_UP_TEMP"

    # Append the UP to DOWN transitions to the output log
    {
        echo "-----------------------------------"
        echo "Endpoints that transitioned from UP to DOWN:"
        cat "$UP_TO_DOWN_TEMP"
        echo "-----------------------------------"
    } >> "$OUTPUT_LOG"

    # Append the DOWN to UP transitions to the output log
    {
        echo "-----------------------------------"
        echo "Endpoints that transitioned from DOWN to UP:"
        cat "$DOWN_TO_UP_TEMP"
        echo "-----------------------------------"
    } >> "$OUTPUT_LOG"

    # Clean up temporary files
    rm "$UP_TEMP" "$DOWN_TEMP" "$UP_TO_DOWN_TEMP" "$DOWN_TO_UP_TEMP"
}

# Run the evaluation function with log file and output log file
evaluate_metrics "$LOG_FILE" "$OUTPUT_LOG"

# Notify the user
echo "Evaluation complete. Results saved to $OUTPUT_LOG"
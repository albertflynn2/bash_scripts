#!/bin/bash

# Check if a log file is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

# Path to the log file
LOG_FILE=$1

# Output log file
OUTPUT_LOG="./endpoints_list.log"
> "$OUTPUT_LOG"  # Clear output log

# Function to extract and list all unique endpoints and analyze metrics
extract_and_analyze_endpoints() {
    local log_file=$1
    local output_log=$2

    awk '
    BEGIN {
        # Initialize arrays to store unique endpoints and metrics
        delete endpoints
        delete metrics
    }

    # Function to process each line and extract endpoints and metrics
    {
        # Extract endpoints
        if ($0 ~ /(I|E)-[0-9]+-EP/) {
            match($0, /(I|E)-[0-9]+-EP/, arr);
            endpoint = arr[0];
            if (!(endpoint in endpoints)) {
                endpoints[endpoint] = 1;
                print endpoint > output_log;
            }
        }

        # Extract metrics
        if ($0 ~ /C=\[[0-9]+\/[0-9]+\] Qd=\[[0-9]+,[0-9]+\] IN\/OUT=\[[0-9]+\/[0-9]+\]\[[0-9]+\/[0-9]+\]/) {
            metrics[NR] = $0;
        }
    }

    END {
        # Print metrics to the output log
        print "\nMetrics:" > output_log;
        for (i in metrics) {
            print metrics[i] > output_log;
        }
    }
    ' output_log="$output_log" "$log_file"
}

# Run the extraction and analysis function with log file and output log file
extract_and_analyze_endpoints "$LOG_FILE" "$OUTPUT_LOG"

# Notify the user
echo "Extraction and analysis complete. Results saved to $OUTPUT_LOG"
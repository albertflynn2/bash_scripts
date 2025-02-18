#!/bin/bash

# Function to analyze the log file
analyze_log() {
    local file_path=$1
    local output_file=$2
    local connection_errors=()
    local network_issues=()
    local resource_issues=()
    local pod_restarts=()
    local authentication_issues=()
    local database_errors=()
    local disk_space_issues=()
    local service_failures=()
    local security_alerts=()
    local configuration_errors=()
    local performance_issues=()
    local timestamps=()

    echo "Starting log analysis..."

    while IFS= read -r line; do
        # Extract timestamp
        if [[ $line =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
            timestamps+=("${BASH_REMATCH[0]}")
        fi

        # Check for connection errors
        if [[ $line =~ connection|timeout|failed|unavailable|disconnected ]]; then
            connection_errors+=("$line")
        fi

        # Check for network issues
        if [[ $line =~ network|latency|unreachable|timeout|packet\ loss ]]; then
            network_issues+=("$line")
        fi

        # Check for resource utilization issues
        if [[ $line =~ cpu|memory|resource|limit|throttle ]]; then
            resource_issues+=("$line")
        fi

        # Check for pod restarts
        if [[ $line =~ restart|crash|oomkill|terminated ]]; then
            pod_restarts+=("$line")
        fi

        # Check for authentication issues
        if [[ $line =~ authentication|login|unauthorized|forbidden ]]; then
            authentication_issues+=("$line")
        fi

        # Check for database errors
        if [[ $line =~ database|db|sql|query|transaction ]]; then
            database_errors+=("$line")
        fi

        # Check for disk space issues
        if [[ $line =~ disk|space|storage|full ]]; then
            disk_space_issues+=("$line")
        fi

        # Check for service failures
        if [[ $line =~ service|failed|unavailable|down ]]; then
            service_failures+=("$line")
        fi

        # Check for security alerts
        if [[ $line =~ security|breach|alert|unauthorized|attack ]]; then
            security_alerts+=("$line")
        fi

        # Check for configuration errors
        if [[ $line =~ configuration|config|setting|parameter ]]; then
            configuration_errors+=("$line")
        fi

        # Check for performance issues
        if [[ $line =~ performance|slow|lag|delay ]]; then
            performance_issues+=("$line")
        fi
    done < "$file_path"

    echo "Log analysis completed."

    # Display main findings and causes for concern in the terminal
    echo "==================== Summary of Findings ===================="
    echo "Issue Type                         | Count"
    echo "---------------------------------------------"
    echo "Total Connection Errors            | ${#connection_errors[@]}"
    echo "Total Network Issues               | ${#network_issues[@]}"
    echo "Total Resource Utilization Issues  | ${#resource_issues[@]}"
    echo "Total Pod Restarts                 | ${#pod_restarts[@]}"
    echo "Total Authentication Issues        | ${#authentication_issues[@]}"
    echo "Total Database Errors              | ${#database_errors[@]}"
    echo "Total Disk Space Issues            | ${#disk_space_issues[@]}"
    echo "Total Service Failures             | ${#service_failures[@]}"
    echo "Total Security Alerts              | ${#security_alerts[@]}"
    echo "Total Configuration Errors         | ${#configuration_errors[@]}"
    echo "Total Performance Issues           | ${#performance_issues[@]}"
    echo ""

    # Display high and low counts
    echo "==================== Highs and Lows ===================="
    echo "Highest Count Issue: Resource Utilization Issues (${#resource_issues[@]})"
    echo "Lowest Count Issue: Pod Restarts (${#pod_restarts[@]})"
    echo ""

    # Display first instance of each issue type
    echo "==================== First Instances of Issues ===================="
    if [ ${#connection_errors[@]} -gt 0 ]; then
        echo "First Connection Error: ${connection_errors[0]}"
    fi
    if [ ${#network_issues[@]} -gt 0 ]; then
        echo "First Network Issue: ${network_issues[0]}"
    fi
    if [ ${#resource_issues[@]} -gt 0 ]; then
        echo "First Resource Utilization Issue: ${resource_issues[0]}"
    fi
    if [ ${#pod_restarts[@]} -gt 0 ]; then
        echo "First Pod Restart: ${pod_restarts[0]}"
    fi
    if [ ${#authentication_issues[@]} -gt 0 ]; then
        echo "First Authentication Issue: ${authentication_issues[0]}"
    fi
    if [ ${#database_errors[@]} -gt 0 ]; then
        echo "First Database Error: ${database_errors[0]}"
    fi
    if [ ${#disk_space_issues[@]} -gt 0 ]; then
        echo "First Disk Space Issue: ${disk_space_issues[0]}"
    fi
    if [ ${#service_failures[@]} -gt 0 ]; then
        echo "First Service Failure: ${service_failures[0]}"
    fi
    if [ ${#security_alerts[@]} -gt 0 ]; then
        echo "First Security Alert: ${security_alerts[0]}"
    fi
    if [ ${#configuration_errors[@]} -gt 0 ]; then
        echo "First Configuration Error: ${configuration_errors[0]}"
    fi
    if [ ${#performance_issues[@]} -gt 0 ]; then
        echo "First Performance Issue: ${performance_issues[0]}"
    fi
    echo ""

    # Output the analysis results to the log file
    {
        echo "==================== Connection Errors ===================="
        echo ""
        if [ ${#connection_errors[@]} -gt 0 ]; then
            printf "%s\n" "${connection_errors[@]}"
        else
            echo "No connection errors found."
        fi
        echo ""
        echo "==================== Network Issues ===================="
        echo ""
        if [ ${#network_issues[@]} -gt 0 ]; then
            printf "%s\n" "${network_issues[@]}"
        else
            echo "No network issues found."
        fi
        echo ""
        echo "==================== Resource Utilization Issues ===================="
        echo ""
        if [ ${#resource_issues[@]} -gt 0 ]; then
            printf "%s\n" "${resource_issues[@]}"
        else
            echo "No resource utilization issues found."
        fi
        echo ""
        echo "==================== Pod Restarts ===================="
        echo ""
        if [ ${#pod_restarts[@]} -gt 0 ]; then
            printf "%s\n" "${pod_restarts[@]}"
        else
            echo "No pod restarts found."
        fi
        echo ""
        echo "==================== Authentication Issues ===================="
        echo ""
        if [ ${#authentication_issues[@]} -gt 0 ]; then
            printf "%s\n" "${authentication_issues[@]}"
        else
            echo "No authentication issues found."
        fi
        echo ""
        echo "==================== Database Errors ===================="
        echo ""
        if [ ${#database_errors[@]} -gt 0 ]; then
            printf "%s\n" "${database_errors[@]}"
        else
            echo "No database errors found."
        fi
        echo ""
        echo "==================== Disk Space Issues ===================="
        echo ""
        if [ ${#disk_space_issues[@]} -gt 0 ]; then
            printf "%s\n" "${disk_space_issues[@]}"
        else
            echo "No disk space issues found."
        fi
        echo ""
        echo "==================== Service Failures ===================="
        echo ""
        if [ ${#service_failures[@]} -gt 0 ]; then
            printf "%s\n" "${service_failures[@]}"
        else
            echo "No service failures found."
        fi
        echo ""
        echo "==================== Security Alerts ===================="
        echo ""
        if [ ${#security_alerts[@]} -gt 0 ]; then
            printf "%s\n" "${security_alerts[@]}"
        else
            echo "No security alerts found."
        fi
        echo ""
        echo "==================== Configuration Errors ===================="
        echo ""
        if [ ${#configuration_errors[@]} -gt 0 ]; then
            printf "%s\n" "${configuration_errors[@]}"
        else
            echo "No configuration errors found."
        fi
        echo ""
        echo "==================== Performance Issues ===================="
        echo ""
        if [ ${#performance_issues[@]} -gt 0 ]; then
            printf "%s\n" "${performance_issues[@]}"
        else
            echo "No performance issues found."
        fi
        echo ""
        
                echo "==================== Summary of Findings ===================="
        printf "%-30s | %-10s\n" "Issue Type" "Count"
        echo "---------------------------------------------"
        printf "%-30s | %-10d\n" "Total Connection Errors" "${#connection_errors[@]}"
        printf "%-30s | %-10d\n" "Total Network Issues" "${#network_issues[@]}"
        printf "%-30s | %-10d\n" "Total Resource Utilization Issues" "${#resource_issues[@]}"
        printf "%-30s | %-10d\n" "Total Pod Restarts" "${#pod_restarts[@]}"
        printf "%-30s | %-10d\n" "Total Authentication Issues" "${#authentication_issues[@]}"
        printf "%-30s | %-10d\n" "Total Database Errors" "${#database_errors[@]}"
        printf "%-30s | %-10d\n" "Total Disk Space Issues" "${#disk_space_issues[@]}"
        printf "%-30s | %-10d\n" "Total Service Failures" "${#service_failures[@]}"
        printf "%-30s | %-10d\n" "Total Security Alerts" "${#security_alerts[@]}"
        printf "%-30s | %-10d\n" "Total Configuration Errors" "${#configuration_errors[@]}"
        printf "%-30s | %-10d\n" "Total Performance Issues" "${#performance_issues[@]}"
        echo ""

        # Highlight main issues or potential issues in table format
        if [ ${#connection_errors[@]} -gt 0 ]; then
            echo ""
            echo "Main Issue: High number of connection errors (${#connection_errors[@]})"
            echo "Connection Errors (Examples)"
            echo "---------------------------------------------"
            for error in "${connection_errors[@]:0:5}"; do
                echo "$error"
            done
            if [ ${#connection_errors[@]} -gt 5 ]; then
                echo "... (and more)"
            fi
            echo "Explanation: Connection errors indicate issues with establishing or maintaining network connections. This could be due to server unavailability, network timeouts, or other connectivity problems."
        fi

        if [ ${#network_issues[@]} -gt 0 ]; then
            echo ""
            echo "Main Issue: High number of network issues (${#network_issues[@]})"
            echo "Network Issues (Examples)"
            echo "---------------------------------------------"
            for issue in "${network_issues[@]:0:5}"; do
                echo "$issue"
            done
            if [ ${#network_issues[@]} -gt 5 ]; then
                echo "... (and more)"
            fi
            echo "Explanation: Network issues can include latency, unreachable servers, packet loss, and other problems affecting network performance. These issues can lead to slow response times and connectivity disruptions."
        fi

        if [ ${#resource_issues[@]} -gt 0 ]; then
            echo ""
            echo "Main Issue: High number of resource utilization issues (${#resource_issues[@]})"
            echo "Resource Utilization Issues (Examples)"
            echo "---------------------------------------------"
            for issue in "${resource_issues[@]:0:5}"; do
                echo "$issue"
            done
            if [ ${#resource_issues[@]} -gt 5 ]; then
                echo "... (and more)"
            fi
            echo "Explanation: Resource utilization issues refer to problems with CPU, memory, or other system resources being overused or throttled. This can lead to performance degradation and system instability."
        fi

        if [ ${#pod_restarts[@]} -gt 0 ]; then
            echo ""
            echo "Main Issue: High number of pod restarts (${#pod_restarts[@]})"
            echo "Pod Restarts (Examples)"
            echo "---------------------------------------------"
            for restart in "${pod_restarts[@]:0:5}"; do
                echo "$restart"
            done
            if [ ${#pod_restarts[@]} -gt 5 ]; then
                echo "... (and more)"
            fi
            echo "Explanation: Pod restarts indicate that containers are frequently restarting, which could be due to crashes, out-of-memory errors, or other critical failures."
        fi

        if [ ${#authentication_issues[@]} -gt 0 ]; then
            echo ""
            echo "Main Issue: High number of authentication issues (${#authentication_issues[@]})"
            echo "Authentication Issues (Examples)"
            echo "---------------------------------------------"
            for issue in "${authentication_issues[@]:0:5}"; do
                echo "$issue"
            done
            if [ ${#authentication_issues[@]} -gt 5 ]; then
                echo "... (and more)"
            fi
            echo "Explanation: Authentication issues indicate problems with user login or authorization, which could lead to users being unable to access the system."
        fi

        if [ ${#database_errors[@]} -gt 0 ]; then
            echo ""
            echo "Main Issue: High number of database errors (${#database_errors[@]})"
            echo "Database Errors (Examples)"
            echo "---------------------------------------------"
            for error in "${database_errors[@]:0:5}"; do
                echo "$error"
            done
            if [ ${#database_errors[@]} -gt 5 ]; then
                echo "... (and more)"
            fi
            echo "Explanation: Database errors indicate issues with database connectivity or queries, which could affect data retrieval and storage operations."
        fi

        if [ ${#disk_space_issues[@]} -gt 0 ]; then
            echo ""
            echo "Main Issue: High number of disk space issues (${#disk_space_issues[@]})"
            echo "Disk Space Issues (Examples)"
            echo "---------------------------------------------"
            for issue in "${disk_space_issues[@]:0:5}"; do
                echo "$issue"
            done
            if [ ${#disk_space_issues[@]} -gt 5 ]; then
                echo "... (and more)"
            fi
            echo "Explanation: Disk space issues indicate that the system is running low on storage, which could lead to failures in writing data or system crashes."
        fi

        if [ ${#service_failures[@]} -gt 0 ]; then
            echo ""
            echo "Main Issue: High number of service failures (${#service_failures[@]})"
            echo "Service Failures (Examples)"
            echo "---------------------------------------------"
            for failure in "${service_failures[@]:0:5}"; do
                echo "$failure"
            done
            if [ ${#service_failures[@]} -gt 5 ]; then
                echo "... (and more)"
            fi
            echo "Explanation: Service failures indicate that specific services or applications are failing, which could disrupt the overall functionality of the system."
        fi

        if [ ${#security_alerts[@]} -gt 0 ]; then
            echo ""
            echo "Main Issue: High number of security alerts (${#security_alerts[@]})"
            echo "Security Alerts (Examples)"
            echo "---------------------------------------------"
            for alert in "${security_alerts[@]:0:5}"; do
                echo "$alert"
            done
            if [ ${#security_alerts[@]} -gt 5 ]; then
                echo "... (and more)"
            fi
            echo "Explanation: Security alerts indicate potential security breaches or unauthorized access attempts, which could compromise the system's integrity."
        fi

        if [ ${#configuration_errors[@]} -gt 0 ]; then
            echo ""
            echo "Main Issue: High number of configuration errors (${#configuration_errors[@]})"
            echo "Configuration Errors (Examples)"
            echo "---------------------------------------------"
            for error in "${configuration_errors[@]:0:5}"; do
                echo "$error"
            done
            if [ ${#configuration_errors[@]} -gt 5 ]; then
                echo "... (and more)"
            fi
            echo "Explanation: Configuration errors indicate issues with system settings or parameters, which could lead to misconfigurations and system instability."
        fi

        if [ ${#performance_issues[@]} -gt 0 ]; then
            echo ""
            echo "Main Issue: High number of performance issues (${#performance_issues[@]})"
            echo "Performance Issues (Examples)"
            echo "---------------------------------------------"
            for issue in "${performance_issues[@]:0:5}"; do
                echo "$issue"
            done
            if [ ${#performance_issues[@]} -gt 5 ]; then
                echo "... (and more)"
            fi
            echo "Explanation: Performance issues indicate that the system is experiencing slowdowns or delays, which could affect user experience and system efficiency."
        fi

        if [ ${#timestamps[@]} -gt 0 ]; then
            echo ""
            echo "Issues occurred at the following times:"
            echo "Timestamp                         | Occurrences"
            echo "---------------------------------------------"
            for timestamp in $(printf "%s\n" "${timestamps[@]}" | sort | uniq -c | sort -nr | head -n 10); do
                echo "$timestamp"
            done
            echo "Explanation: The above timestamps indicate when the most frequent issues occurred. Analyzing these times can help identify patterns or specific events that triggered the problems."
        else
            echo "No timestamps found in the log."
        fi

    } > "$output_file"

    echo "Analysis results written to $output_file"
}

# Check if the script is run with a log file argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <log_file_path>"
    exit 1
fi

log_file_path="$1"
output_file_path="analysis_results.txt"
analyze_log "$log_file_path" "$output_file_path"

function Analyze-Log {
    param (
        [string]$FilePath,
        [string]$OutputFile
    )

    $connectionErrors = @()
    $networkIssues = @()
    $resourceIssues = @()
    $podRestarts = @()
    $authenticationIssues = @()
    $databaseErrors = @()
    $diskSpaceIssues = @()
    $serviceFailures = @()
    $securityAlerts = @()
    $configurationErrors = @()
    $performanceIssues = @()
    $cpuIssues = @()
    $memoryIssues = @()
    $tpsIssues = @()
    $gcIssues = @()
    $timestamps = @()

    Write-Output "Starting log analysis..."

    $isJson = $false
    $isNdjson = $false

    # Determine the log format
    $firstLine = Get-Content $FilePath -First 1
    if ($firstLine.Trim().StartsWith("{")) {
        $isJson = $true
    } elseif ($firstLine.Trim().StartsWith("{") -or $firstLine.Trim().StartsWith("[")) {
        $isNdjson = $true
    }

    if ($isJson) {
        $logEntries = Get-Content $FilePath | ConvertFrom-Json
    } elseif ($isNdjson) {
        $logEntries = Get-Content $FilePath | ForEach-Object { $_ | ConvertFrom-Json }
    } else {
        $logEntries = Get-Content $FilePath
    }

    $logEntries | ForEach-Object {
        $line = $_

        # Extract timestamp
        if ($isJson -or $isNdjson) {
            if ($line.timestamp) {
                $timestamps += $line.timestamp
            }
        } else {
            if ($line -match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}') {
                $timestamps += $matches[0]
            }
        }

        # Check for connection errors
        if ($line -match 'connection|timeout|failed|unavailable|disconnected') {
            $connectionErrors += $line
        }

        # Check for network issues
        if ($line -match 'network|latency|unreachable|timeout|packet loss') {
            $networkIssues += $line
        }

        # Check for resource utilization issues
        if ($line -match 'cpu|memory|resource|limit|throttle') {
            $resourceIssues += $line
        }

        # Check for pod restarts
        if ($line -match 'restart|crash|oomkill|terminated') {
            $podRestarts += $line
        }

        # Check for authentication issues
        if ($line -match 'authentication|login|unauthorized|forbidden') {
            $authenticationIssues += $line
        }

        # Check for database errors
        if ($line -match 'database|db|sql|query|transaction') {
            $databaseErrors += $line
        }

        # Check for disk space issues
        if ($line -match 'disk|space|storage|full') {
            $diskSpaceIssues += $line
        }

        # Check for service failures
        if ($line -match 'service|failed|unavailable|down') {
            $serviceFailures += $line
        }

        # Check for security alerts
        if ($line -match 'security|breach|alert|unauthorized|attack') {
            $securityAlerts += $line
        }

        # Check for configuration errors
        if ($line -match 'configuration|config|setting|parameter') {
            $configurationErrors += $line
        }

        # Check for performance issues
        if ($line -match 'performance|slow|lag|delay') {
            $performanceIssues += $line
        }

        # Check for CPU issues
        if ($line -match 'cpu|processor|load') {
            $cpuIssues += $line
        }

        # Check for memory issues
        if ($line -match 'memory|ram|heap') {
            $memoryIssues += $line
        }

        # Check for TPS issues
        if ($line -match 'tps|transactions per second') {
            $tpsIssues += $line
        }

        # Check for GC issues
        if ($line -match 'gc|garbage collection') {
            $gcIssues += $line
        }
    }

    Write-Output "Log analysis completed."

    # Prepare the output for the log file
    $output = @()
    $output += "==================== Summary of Findings ===================="
    $output += "Issue Type                         | Count"
    $output += "---------------------------------------------"
    $output += "Total Connection Errors            | $($connectionErrors.Count)"
    $output += "Total Network Issues               | $($networkIssues.Count)"
    $output += "Total Resource Utilization Issues  | $($resourceIssues.Count)"
    $output += "Total Pod Restarts                 | $($podRestarts.Count)"
    $output += "Total Authentication Issues        | $($authenticationIssues.Count)"
    $output += "Total Database Errors              | $($databaseErrors.Count)"
    $output += "Total Disk Space Issues            | $($diskSpaceIssues.Count)"
    $output += "Total Service Failures             | $($serviceFailures.Count)"
    $output += "Total Security Alerts              | $($securityAlerts.Count)"
    $output += "Total Configuration Errors         | $($configurationErrors.Count)"
    $output += "Total Performance Issues           | $($performanceIssues.Count)"
    $output += "Total CPU Issues                   | $($cpuIssues.Count)"
    $output += "Total Memory Issues                | $($memoryIssues.Count)"
    $output += "Total TPS Issues                   | $($tpsIssues.Count)"
    $output += "Total GC Issues                    | $($gcIssues.Count)"
    $output += ""

    # Display high and low counts
    $issueCounts = @{
        "Connection Errors" = $connectionErrors.Count
        "Network Issues" = $networkIssues.Count
        "Resource Utilization Issues" = $resourceIssues.Count
        "Pod Restarts" = $podRestarts.Count
        "Authentication Issues" = $authenticationIssues.Count
        "Database Errors" = $databaseErrors.Count
        "Disk Space Issues" = $diskSpaceIssues.Count
        "Service Failures" = $serviceFailures.Count
        "Security Alerts" = $securityAlerts.Count
        "Configuration Errors" = $configurationErrors.Count
        "Performance Issues" = $performanceIssues.Count
        "CPU Issues" = $cpuIssues.Count
        "Memory Issues" = $memoryIssues.Count
        "TPS Issues" = $tpsIssues.Count
        "GC Issues" = $gcIssues.Count
    }
    $highestIssue = $issueCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
    $lowestIssue = $issueCounts.GetEnumerator() | Sort-Object Value | Select-Object -First 1
    $output += "==================== Highs and Lows ===================="
    $output += ("Highest Count Issue: {0} ({1})" -f $highestIssue.Key, $highestIssue.Value)
    $output += ("Lowest Count Issue: {0} ({1})" -f $lowestIssue.Key, $lowestIssue.Value)
    $output += ""

    # Display first instance and highest level of each issue type
    $output += "==================== First Instance and Highest Level of Issues ===================="
    $output += "Issue Type                         | First Instance                         | Highest Level"
    $output += "---------------------------------------------"
    if ($connectionErrors.Count -gt 0) {
        $output += ("Connection Errors                  | {0} | {1}" -f $connectionErrors[0], $connectionErrors | Measure-Object -Maximum)
    }
    if ($networkIssues.Count -gt 0) {
        $output += ("Network Issues                     | {0} | {1}" -f $networkIssues[0], $networkIssues | Measure-Object -Maximum)
    }
    if ($resourceIssues.Count -gt 0) {
        $output += ("Resource Utilization Issues        | {0} | {1}" -f $resourceIssues[0], $resourceIssues | Measure-Object -Maximum)
    }
    if ($podRestarts.Count -gt 0) {
        $output += ("Pod Restarts                       | {0} | {1}" -f $podRestarts[0], $podRestarts | Measure-Object -Maximum)
    }
    if ($authenticationIssues.Count -gt 0) {
        $output += ("Authentication Issues              | {0} | {1}" -f $authenticationIssues[0], $authenticationIssues | Measure-Object -Maximum)
    }
    if ($databaseErrors.Count -gt 0) {
        $output += ("Database Errors                    | {0} | {1}" -f $databaseErrors[0], $databaseErrors | Measure-Object -Maximum)
    }
        if ($diskSpaceIssues.Count -gt 0) {
        $output += ("Disk Space Issues                  | {0} | {1}" -f $diskSpaceIssues[0], $diskSpaceIssues | Measure-Object -Maximum)
    }
    if ($serviceFailures.Count -gt 0) {
        $output += ("Service Failures                   | {0} | {1}" -f $serviceFailures[0], $serviceFailures | Measure-Object -Maximum)
    }
    if ($securityAlerts.Count -gt 0) {
        $output += ("Security Alerts                    | {0} | {1}" -f $securityAlerts[0], $securityAlerts | Measure-Object -Maximum)
    }
    if ($configurationErrors.Count -gt 0) {
        $output += ("Configuration Errors               | {0} | {1}" -f $configurationErrors[0], $configurationErrors | Measure-Object -Maximum)
    }
    if ($performanceIssues.Count -gt 0) {
        $output += ("Performance Issues                 | {0} | {1}" -f $performanceIssues[0], $performanceIssues | Measure-Object -Maximum)
    }
    if ($cpuIssues.Count -gt 0) {
        $output += ("CPU Issues                         | {0} | {1}" -f $cpuIssues[0], $cpuIssues | Measure-Object -Maximum)
    }
    if ($memoryIssues.Count -gt 0) {
        $output += ("Memory Issues                      | {0} | {1}" -f $memoryIssues[0], $memoryIssues | Measure-Object -Maximum)
    }
    if ($tpsIssues.Count -gt 0) {
        $output += ("TPS Issues                         | {0} | {1}" -f $tpsIssues[0], $tpsIssues | Measure-Object -Maximum)
    }
    if ($gcIssues.Count -gt 0) {
        $output += ("GC Issues                          | {0} | {1}" -f $gcIssues[0], $gcIssues | Measure-Object -Maximum)
    }
    $output += ""

    # Highlight main issues or potential issues in table format
    if ($connectionErrors.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of connection errors ($($connectionErrors.Count))"
        $output += "Connection Errors (Examples)"
        $output += "---------------------------------------------"
        $connectionErrors[0..([math]::Min(4, $connectionErrors.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($connectionErrors.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: Connection errors indicate issues with establishing or maintaining network connections. This could be due to server unavailability, network timeouts, or other connectivity problems."
    }

    if ($networkIssues.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of network issues ($($networkIssues.Count))"
        $output += "Network Issues (Examples)"
        $output += "---------------------------------------------"
        $networkIssues[0..([math]::Min(4, $networkIssues.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($networkIssues.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: Network issues indicate problems with network connectivity, such as latency, packet loss, or unreachable services."
    }

    if ($resourceIssues.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of resource utilization issues ($($resourceIssues.Count))"
        $output += "Resource Utilization Issues (Examples)"
        $output += "---------------------------------------------"
        $resourceIssues[0..([math]::Min(4, $resourceIssues.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($resourceIssues.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: Resource utilization issues indicate that the system is experiencing high CPU or memory usage, which could lead to performance degradation."
    }

    if ($podRestarts.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of pod restarts ($($podRestarts.Count))"
        $output += "Pod Restarts (Examples)"
        $output += "---------------------------------------------"
        $podRestarts[0..([math]::Min(4, $podRestarts.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($podRestarts.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: Pod restarts indicate that containers are crashing or being terminated, which could affect the availability and stability of services."
    }

    if ($authenticationIssues.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of authentication issues ($($authenticationIssues.Count))"
        $output += "Authentication Issues (Examples)"
        $output += "---------------------------------------------"
        $authenticationIssues[0..([math]::Min(4, $authenticationIssues.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($authenticationIssues.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: Authentication issues indicate problems with user login or authorization, which could prevent users from accessing the system."
    }

    if ($databaseErrors.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of database errors ($($databaseErrors.Count))"
        $output += "Database Errors (Examples)"
        $output += "---------------------------------------------"
        $databaseErrors[0..([math]::Min(4, $databaseErrors.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($databaseErrors.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: Database errors indicate issues with database connectivity or queries, which could affect data retrieval and storage operations."
    }

    if ($diskSpaceIssues.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of disk space issues ($($diskSpaceIssues.Count))"
        $output += "Disk Space Issues (Examples)"
        $output += "---------------------------------------------"
        $diskSpaceIssues[0..([math]::Min(4, $diskSpaceIssues.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($diskSpaceIssues.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: Disk space issues indicate that the system is running low on storage, which could lead to failures in writing data or system crashes."
    }

    if ($serviceFailures.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of service failures ($($serviceFailures.Count))"
        $output += "Service Failures (Examples)"
        $output += "---------------------------------------------"
        $serviceFailures[0..([math]::Min(4, $serviceFailures.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($serviceFailures.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: Service failures indicate that specific services or applications are failing, which could disrupt the overall functionality of the system."
    }

    if ($securityAlerts.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of security alerts ($($securityAlerts.Count))"
        $output += "Security Alerts (Examples)"
        $output += "---------------------------------------------"
        $securityAlerts[0..([math]::Min(4, $securityAlerts.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($securityAlerts.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: Security alerts indicate potential security breaches or unauthorized access attempts, which could compromise the system's integrity."
    }

    if ($configurationErrors.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of configuration errors ($($configurationErrors.Count))"
        $output += "Configuration Errors (Examples)"
        $output += "---------------------------------------------"
        $configurationErrors[0..([math]::Min(4, $configurationErrors.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($configurationErrors.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: Configuration errors indicate issues with system settings or parameters, which could lead to misconfigurations and system instability."
    }

    if ($performanceIssues.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of performance issues ($($performanceIssues.Count))"
        $output += "Performance Issues (Examples)"
        $output += "---------------------------------------------"
        $performanceIssues[0..([math]::Min(4, $performanceIssues.Count - 1))] | ForEach-Object {
                $output += $_
        }
        if ($performanceIssues.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: Performance issues indicate that the system is experiencing slowdowns or delays, which could affect user experience and system efficiency."
    }

    if ($cpuIssues.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of CPU issues ($($cpuIssues.Count))"
        $output += "CPU Issues (Examples)"
        $output += "---------------------------------------------"
        $cpuIssues[0..([math]::Min(4, $cpuIssues.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($cpuIssues.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: CPU issues indicate high processor usage, which could lead to performance bottlenecks."
    }

    if ($memoryIssues.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of memory issues ($($memoryIssues.Count))"
        $output += "Memory Issues (Examples)"
        $output += "---------------------------------------------"
        $memoryIssues[0..([math]::Min(4, $memoryIssues.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($memoryIssues.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: Memory issues indicate high RAM usage, which could lead to performance degradation or system crashes."
    }

    if ($tpsIssues.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of TPS issues ($($tpsIssues.Count))"
        $output += "TPS Issues (Examples)"
        $output += "---------------------------------------------"
        $tpsIssues[0..([math]::Min(4, $tpsIssues.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($tpsIssues.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: TPS issues indicate problems with transactions per second, which could affect the system's ability to handle requests efficiently."
    }

    if ($gcIssues.Count -gt 0) {
        $output += ""
        $output += "Main Issue: High number of GC issues ($($gcIssues.Count))"
        $output += "GC Issues (Examples)"
        $output += "---------------------------------------------"
        $gcIssues[0..([math]::Min(4, $gcIssues.Count - 1))] | ForEach-Object {
            $output += $_
        }
        if ($gcIssues.Count -gt 5) {
            $output += "... (and more)"
        }
        $output += "Explanation: GC issues indicate problems with garbage collection, which could lead to memory leaks or performance degradation."
    }

    if ($timestamps.Count -gt 0) {
        $output += ""
        $output += "Issues occurred at the following times:"
        $output += "Timestamp                         | Occurrences"
        $output += "---------------------------------------------"
        $timestamps | Group-Object | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
            $output += "$($_.Name)                         | $($_.Count)"
        }
        $output += "Explanation: The above timestamps indicate when the most frequent issues occurred. Analyzing these times can help identify patterns or specific events that triggered the problems."
    } else {
        $output += "No timestamps found in the log."
    }

    # Output the analysis results to the log file
    $output | Out-File -FilePath $OutputFile

    # Display the same output in the terminal
    $output | ForEach-Object { Write-Output $_ }

    Write-Output "Analysis results written to $OutputFile"
}

# Check if the script is run with a log file argument
if ($args.Count -ne 1) {
    Write-Output "Usage: .\Analyze-Log.ps1 <log_file_path>"
    exit 1
}

$logFilePath = $args[0]
$outputFilePath = "analysis_results.txt"
Analyze-Log -FilePath $logFilePath -OutputFile $outputFilePath

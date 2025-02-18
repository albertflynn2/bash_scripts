#!/bin/bash

LOG_FILE="helm_analysis.log"

# Function to log messages
log_message() {
    local message=$1
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Function to gather Helm environment details
gather_helm_details() {
    log_message "Gathering Helm environment details..."
    helm list --all-namespaces | tee -a "$LOG_FILE"
    helm repo list | tee -a "$LOG_FILE"
}

# Function to check Helm release status
check_helm_release_status() {
    local release_name=$1
    local namespace=$2
    log_message "Checking status of Helm release: $release_name in namespace: $namespace"
    helm status "$release_name" --namespace "$namespace" | tee -a "$LOG_FILE"
}

# Function to detect common Helm issues
detect_helm_issues() {
    log_message "Detecting common Helm issues..."
    
    # Check for failed releases
    failed_releases=$(helm list --all-namespaces --failed -o json | jq -r '.[] | "\(.name) \(.namespace)"')
    if [ -n "$failed_releases" ]; then
        log_message "Detected failed releases:"
        echo "$failed_releases" | tee -a "$LOG_FILE"
    else
        log_message "No failed releases detected."
    fi

    # Check for outdated charts
    outdated_charts=$(helm list --all-namespaces -o json | jq -r '.[] | select(.chart | test("-[0-9]+\\.[0-9]+\\.[0-9]+$")) | "\(.name) \(.namespace) \(.chart)"')
    if [ -n "$outdated_charts" ]; then
        log_message "Detected outdated charts:"
        echo "$outdated_charts" | tee -a "$LOG_FILE"
    else
        log_message "No outdated charts detected."
    fi

    # Check for missing dependencies
    log_message "Checking for missing dependencies..."
    chart_files=$(find / -name "Chart.yaml" 2>/dev/null)
    if [ -n "$chart_files" ]; then
        for chart_file in $chart_files; do
            chart_dir=$(dirname "$chart_file")
            log_message "Found Chart.yaml at: $chart_file"
            dependencies=$(cd "$chart_dir" && helm dependency list 2>&1)
            if [[ $dependencies == *"no dependencies"* ]]; then
                log_message "WARNING: No dependencies found in $chart_file"
            elif [[ $dependencies == *"missing"* ]]; then
                log_message "ERROR: Missing dependencies in $chart_file"
                echo "$dependencies" | tee -a "$LOG_FILE"
            else
                echo "$dependencies" | tee -a "$LOG_FILE"
            fi
        done
    else
        log_message "Error: No Chart.yaml files found"
    fi
}

# Function to check Helm and Kubernetes compatibility
check_helm_k8s_compatibility() {
    log_message "Checking Helm and Kubernetes compatibility..."
    helm_version=$(helm version --short | awk '{print $2}')
    k8s_version=$(kubectl version --client --short | awk -F ': ' '/Server Version/ {print $2}')
    
    log_message "Helm version: $helm_version"
    log_message "Kubernetes version: $k8s_version"

    # Compatibility check logic based on Helm and Kubernetes version skew policy
    compatible=false
    case "$helm_version" in
        v3.14.*)
            if [[ "$k8s_version" =~ ^v1\.(2[6-9])\..* ]]; then
                compatible=true
            fi
            ;;
        v3.13.*)
            if [[ "$k8s_version" =~ ^v1\.(2[5-8])\..* ]]; then
                compatible=true
            fi
            ;;
        v3.12.*)
            if [[ "$k8s_version" =~ ^v1\.(2[4-7])\..* ]]; then
                compatible=true
            fi
            ;;
        # Add more cases as needed based on the version skew policy
        *)
            log_message "Helm version $helm_version is not explicitly checked for compatibility."
            ;;
    esac

    if $compatible; then
        log_message "Helm version $helm_version is compatible with Kubernetes version $k8s_version."
    else
        log_message "Warning: Helm version $helm_version may not be compatible with Kubernetes version $k8s_version."
    fi
}

# Main script execution
main() {
    gather_helm_details
    check_helm_k8s_compatibility
    detect_helm_issues
}

# Run the main function
main

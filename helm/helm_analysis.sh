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
    helm dependency list | tee -a "$LOG_FILE"
}

# Function to check Helm and Kubernetes compatibility
check_helm_k8s_compatibility() {
    log_message "Checking Helm and Kubernetes compatibility..."
    helm_version=$(helm version --short | awk '{print $2}')
    k8s_version=$(kubectl version --short | grep Server | awk '{print $3}')
    
    log_message "Helm version: $helm_version"
    log_message "Kubernetes version: $k8s_version"

    # Add compatibility check logic here based on Helm and Kubernetes version skew policy
    # For example, Helm 3.14.x is compatible with Kubernetes 1.29.x - 1.26.x
    # Refer to Helm's version skew policy for detailed compatibility information
    # https://helm.sh/docs/topics/version_skew/
}

# Function to attempt to fix Helm issues
fix_helm_issues() {
    log_message "Attempting to fix Helm issues..."
    
    # Retry failed releases
    for release in $failed_releases; do
        release_name=$(echo "$release" | awk '{print $1}')
        namespace=$(echo "$release" | awk '{print $2}')
        log_message "Retrying upgrade for failed release: $release_name in namespace: $namespace"
        if ! helm upgrade "$release_name" --namespace "$namespace"; then
            log_message "Error: Failed to retry upgrade for release: $release_name"
        else
            log_message "Successfully retried upgrade for release: $release_name"
        fi
    done

    # Upgrade outdated charts
    for chart in $outdated_charts; do
        release_name=$(echo "$chart" | awk '{print $1}')
        namespace=$(echo "$chart" | awk '{print $2}')
        chart_name=$(echo "$chart" | awk '{print $3}')
        log_message "Upgrading outdated chart: $chart_name for release: $release_name in namespace: $namespace"
        if ! helm upgrade "$release_name" "$chart_name" --namespace "$namespace"; then
            log_message "Error: Failed to upgrade chart: $chart_name for release: $release_name"
        else
            log_message "Successfully upgraded chart: $chart_name for release: $release_name"
        fi
    done

    # Fix missing dependencies
    log_message "Fixing missing dependencies..."
    if ! helm dependency update; then
        log_message "Error: Failed to update dependencies."
    else
        log_message "Successfully updated dependencies."
    fi
}

# Main script execution
main() {
    gather_helm_details
    check_helm_k8s_compatibility
    detect_helm_issues
    fix_helm_issues
}

# Run the main function
main

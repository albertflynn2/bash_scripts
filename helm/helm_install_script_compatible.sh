#!/bin/bash

# Get the Kubernetes version
k8s_version=$(kubectl version --short | awk -Fv '/Server Version: / {print $3}')

# Define compatible Helm versions (this is an example, adjust as needed)
declare -A helm_versions
helm_versions["1.18"]="v3.2.0"
helm_versions["1.19"]="v3.3.0"
helm_versions["1.20"]="v3.4.0"
helm_versions["1.21"]="v3.5.0"
helm_versions["1.22"]="v3.6.0"
helm_versions["1.23"]="v3.7.0"
helm_versions["1.24"]="v3.8.0"

# Get the compatible Helm version
helm_version=${helm_versions[$k8s_version]}

if [ -z "$helm_version" ]; then
  echo "No compatible Helm version found for Kubernetes version $k8s_version"
  exit 1
fi

# Download and use the compatible Helm version
curl -LO https://get.helm.sh/helm-$helm_version-linux-amd64.tar.gz
tar -zxvf helm-$helm_version-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm

# Perform the Helm upgrade
helm upgrade upf ./deploy/charts/upf -n upf -f ./env/example/values.yaml --set control-center.dataMigrator.enabled=true  --set control-center.dataMigrator.waitFor=true --wait --timeout 60m 


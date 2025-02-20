#!/bin/bash

# Function to stop and remove containers using a specific image
stop_and_remove_containers() {
    local image_id=$1
    local containers=$(docker ps -a -q --filter "ancestor=$image_id")
    if [ -n "$containers" ]; then
        echo "Stopping containers using image $image_id..."
        docker stop $containers || { echo "Failed to stop containers using image $image_id"; exit 1; }
        echo "Removing containers using image $image_id..."
        docker rm $containers || { echo "Failed to remove containers using image $image_id"; exit 1; }
    fi
}

# Function to delete images
delete_images() {
    local image_id=$1
    echo "Deleting image $image_id..."
    docker rmi -f $image_id || { echo "Failed to delete image $image_id"; exit 1; }
}

# Function to clean Docker system
clean_docker_system() {
    echo "Cleaning Docker system..."
    docker system prune -a -f || { echo "Failed to clean Docker system"; exit 1; }
}

# Function to re-pull, tag, and push images
re_pull_tag_push_images() {
    local registry=$1
    local image_id=$2
    local image_name=$(docker inspect --format='{{.RepoTags}}' $image_id | sed 's/[][]//g' | awk -F':' '{print $1}')
    local new_tag="${image_name}:latest"
    
    echo "Re-pulling image $image_name from registry $registry..."
    docker pull $registry/$image_name || { echo "Failed to re-pull image $image_name from registry $registry"; exit 1; }
    
    echo "Tagging image $registry/$image_name as $new_tag..."
    docker tag $registry/$image_name $new_tag || { echo "Failed to tag image $registry/$image_name as $new_tag"; exit 1; }
    
    echo "Pushing image $new_tag to registry $registry..."
    docker push $new_tag || { echo "Failed to push image $new_tag to registry $registry"; exit 1; }
}

# Function to log actions
log_action() {
    local message=$1
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message"
}

# Main script
main() {
    if [ $# -ne 1 ]; then
        echo "Usage: $0 <registry-url>"
        exit 1
    fi
    local registry=$1
    # List all Docker images
    local images=$(docker images -q)
    # Iterate over each image and handle issues
    for image_id in $images; do
        # Check if image is being used by running containers
        local containers=$(docker ps -q --filter "ancestor=$image_id")
        if [ -n "$containers" ]; then
            stop_and_remove_containers $image_id
        fi
        # Delete the image
        delete_images $image_id
        # Re-pull, tag, and push the image
        re_pull_tag_push_images $registry $image_id
    done
    # Clean Docker system
    clean_docker_system
}

# Execute main function
main "$@"
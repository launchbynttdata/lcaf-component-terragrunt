#!/bin/bash

# Constants
BASE_DIR='.'
SKELETON_YAML="$BASE_DIR/skeleton.yaml"
INPUTS_YAML="$BASE_DIR/inputs.yaml"
ENV_DIR="$BASE_DIR/env"

# Function to create files
create_file() {
    local file="$1"
    local content="$2"
    cat <<EOL > "$file"
# Copyright 2023 Launch, LLC. All Rights Reserved.
$content
EOL
}

# Create subdirectories under the 'env' directory
if [ ! -d "$ENV_DIR" ]; then
    echo "Directory '$ENV_DIR' not found. Creating the directory named env."
    mkdir -p "$ENV_DIR"
fi

envs=$(yq -r .envs $SKELETON_YAML)

# Iterate through environments
environments=$(echo "$envs" | jq '{ "envs": . }' | jq -r '.envs[]? | keys[]')
for environment in $environments; do
    environment_dir="$ENV_DIR/$environment"
    mkdir -p "$environment_dir"

    # Use jq to iterate through the input JSON to extract the git_tag for the current environment
    git_tag=$(echo "$envs" | jq '{ "envs": . }' | jq ".envs[]? | select(has(\"$environment\")) | .\"$environment\".git_tag?")

    # Iterate through regions under each environment
    regions=$(echo "$envs" | jq '{ "envs": . }' | jq -r ".envs[]? | .\"$environment\".regions[]? | keys[]")
    for region in $regions; do
        region_dir="$environment_dir/$region"
        mkdir -p "$region_dir"

        # Iterate through instances under each region
        instances=$(echo "$envs" | jq '{ "envs": . }' | jq -r ".envs[]? | .\"$environment\".regions[]? | .\"$region\".instances[]?")
        for instance in $instances; do
            instance_dir="$region_dir/$instance"
            mkdir -p "$instance_dir"
            echo "Created directory: $instance_dir"
          
            # Create and populate inputs.yaml file
            inputs_yaml_file="$instance_dir/inputs.yaml"
            content="git_tag: $git_tag"
            create_file "$inputs_yaml_file" "$content"

            # Create and populate terraform.tfvars file
            terraform_tfvars_file="$instance_dir/terraform.tfvars"
            content=""
            create_file "$terraform_tfvars_file" "$content"
        done
    done
done

echo "Script completed."

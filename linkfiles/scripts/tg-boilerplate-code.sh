#!/bin/bash

# Constants
BASE_DIR='.'
SKELETON_YAML="$BASE_DIR/skeleton.yaml"
INPUTS_YAML="$BASE_DIR/inputs.yaml"
COMMON_DIR="$BASE_DIR/common"
ENV_DIR="$BASE_DIR/env"
ACCOUNTS_JSON="$BASE_DIR/accounts.json"

# Function to extract values from a YAML file
extract_values() {
    local key="$1"
    local yaml_file="$2"
    yq -r ".$key" "$yaml_file"
}

# Function to create HCL files
create_hcl_file() {
    local file="$1"
    local content="$2"
    cat <<EOL > "$file"
# Copyright 2023 Launch, LLC. All Rights Reserved.
$content
EOL
}

# Function to extract key-value pairs for accounts.json
generate_accounts_json() {
    local input="$1"

    # Use jq to iterate through the input JSON and create key-value pairs
    accounts_json="$accounts_json$(echo "$input" | jq '{ "envs": . }' | jq -r '.envs[] | to_entries[] | { (.key): .value.profile }' | jq -s 'add')"

    # Write accounts.json to a file
    echo "$accounts_json" > accounts.json
    echo "Generated accounts.json:"
}

# Extract values from skeleton.yaml
naming_prefix=$(extract_values "naming_prefix" "$SKELETON_YAML")
git_repo_url=$(extract_values "git_repo_url" "$SKELETON_YAML")
module_file_name=$(extract_values "module_file_name" "$SKELETON_YAML")

# Create accounts.json file
envs=$(yq -r .envs $SKELETON_YAML)
generate_accounts_json "$envs"

# Create subdirectories under the 'env' directory
if [ ! -d "$COMMON_DIR" ]; then
    echo "Directory '$COMMON_DIR' not found. Creating the directory named common."
    mkdir -p "$COMMON_DIR"
fi

# Create and populate .hcl
module_file="$COMMON_DIR/$module_file_name"
content="terraform {
  source = \"git::$git_repo_url//.?ref=\${local.git_tag}\"
}

locals {
  inputs = yamldecode(file(\"\${get_terragrunt_dir()}/$INPUTS_YAML\"))
  git_tag = local.inputs.git_tag
}"
create_hcl_file "$module_file" "$content"

# Create inputs.yaml file
inputs_file="$INPUTS_YAML"
content="naming_prefix: $naming_prefix"
create_hcl_file "$inputs_file" "$content"

# Create subdirectories under the 'env' directory
if [ ! -d "$ENV_DIR" ]; then
    echo "Directory '$ENV_DIR' not found. Creating the directory named env."
    mkdir -p "$ENV_DIR"
fi

# Iterate through environments
environments=$(echo "$envs" | jq '{ "envs": . }' | jq -r '.envs[]? | keys[]')
for environment in $environments; do
    environment_dir="$ENV_DIR/$environment"
    mkdir -p "$environment_dir"

    account_hcl_file="$environment_dir/account.hcl"
    content="locals {
  account_name = \"$environment\"
}"
    create_hcl_file "$account_hcl_file" "$content"

    # Iterate through regions under each environment
    regions=$(echo "$envs" | jq '{ "envs": . }' | jq -r ".envs[]? | .\"$environment\".regions[]? | keys[]")
    for region in $regions; do
        region_dir="$environment_dir/$region"
        mkdir -p "$region_dir"

        region_hcl_file="$region_dir/region.hcl"
        content="locals {
  env_region = \"$region\"
}"
        create_hcl_file "$region_hcl_file" "$content"

        # Iterate through instances under each region
        instances=$(echo "$envs" | jq '{ "envs": . }' | jq -r ".envs[]? | .\"$environment\".regions[]? | .\"$region\".instances[]?")
        for instance in $instances; do
            instance_dir="$region_dir/$instance"
            mkdir -p "$instance_dir"
            echo "Created directory: $instance_dir"

            # Stage 2: Create and populate terragrunt.hcl
            terragrunt_hcl_file="$instance_dir/terragrunt.hcl"
            content="include \"root\" {
  path = find_in_parent_folders()
}

include \"common\" {
  path = \"\${get_repo_root()}/common/$module_file_name\"
}

inputs = {
  # Override inputs go here
}"
            create_hcl_file "$terragrunt_hcl_file" "$content"
        done
    done
done

echo "Script completed."

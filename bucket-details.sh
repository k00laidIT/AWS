#!/bin/bash

# Provides discovery information about AWS S3 buckets in a given AWS S3 account.
# Please set the AWS_PROFILE parameter to your defined profile before hand
# List S3 Buckets
buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

printf "%-30s | %-12s | %-12s | %-14s | %-12s | %-16s\n" "Bucket Name" "Service" "Versioning" "Object Lock" "Total Size" "Avg Object Size"
printf "%.s-" {1..110}
echo

for bucket in $buckets; do
    # Service Type: S3 (we'll flag Glacier via storage class below)
    service="S3"

    # Get Versioning status
    versioning=$(aws s3api get-bucket-versioning --bucket $bucket --query 'Status' --output text 2>/dev/null)
    if [ "$versioning" == "Enabled" ]; then
        versioning="Enabled"
    elif [ "$versioning" == "Suspended" ]; then
        versioning="Suspended"
    else
        versioning="Disabled"
    fi

    # Get Object Lock configuration
    object_lock=$(aws s3api get-object-lock-configuration --bucket $bucket --query 'ObjectLockConfiguration.ObjectLockEnabled' --output text 2>/dev/null)
    if [ "$object_lock" == "Enabled" ]; then
        object_lock="Enabled"
    else
        object_lock="Disabled"
    fi

    # Get total object count and total size
    result=$(aws s3 ls s3://$bucket --recursive --human-readable --summarize 2>/dev/null | tail -2)
    total_objects=$(echo "$result" | grep "Total Objects:" | awk '{print $3}')
    total_size_bytes=$(echo "$result" | grep "Total Size:" | awk '{print $3}')
    total_size_hr=$(echo "$result" | grep "Total Size:" | awk '{print $4,$5}')  # Human-readable
    avg_size="N/A"
    if [[ "$total_objects" =~ ^[0-9]+$ ]] && [ "$total_objects" -gt "0" ]; then
        avg_size=$(awk "BEGIN { printf \"%.2f\", $total_size_bytes / $total_objects }")" bytes"
    fi

    # Print data
    printf "%-30s | %-12s | %-12s | %-14s | %-12s | %-16s\n" \
        "$bucket" "$service" "$versioning" "$object_lock" "$total_size_hr" "$avg_size"
done

# List legacy Glacier Vaults, if any
vaults=$(aws glacier list-vaults --account-id - --query "VaultList[].VaultName" --output text 2>/dev/null)
if [ -n "$vaults" ]; then
    for vault in $vaults; do
        # For Glacier Vaults, only limited details available
        printf "%-30s | %-12s | %-12s | %-14s | %-12s | %-16s\n" \
            "$vault" "GlacierVault" "N/A" "N/A" "Use Glacier API" "N/A"
    done
fi

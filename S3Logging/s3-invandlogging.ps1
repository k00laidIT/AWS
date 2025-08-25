# ------------------------------------------------------------------------------
# File: s3-invandlogging.ps1
# Purpose: Within a given AWS account will enable access loging and/or s3 inventory 
# service to write to a provided bucket for any buckets within that account
#
# Author: Jim Jones, jim@koolaid.info
# Created: 2025-07-03
#
# Prerequisites:
#   1. Ensure you have the AWS Tools for PowerShell installed and configured with 
#       appropriate credentials.
#   2. Identify a destination bucket for storing inventory reports and access logs.
#   3. Make sure you have the necessary permissions to modify bucket configurations.
#
# Verify configuration:
#   Check inventory configuration for a sample bucket:
#       Get-S3BucketInventoryConfiguration -BucketName "sample-bucket-name" -Id "InventoryConfig"
#   Check logging configuration for a sample bucket:
#       Get-S3BucketLogging -BucketName "sample-bucket-name"
#
# Usage:
# ./s3-invandlogging.ps1 -regionId "us-east-2" `
#   -awsProfile "myAWSProfile" `
#   -analyticsBucket "us-east-2-myaccount-analytics1" `
#   -retainForDays "90" `
#   -Analytics 
#   -S3Inv 
#
# Sources
#   Configuring Amazon S3 Inventory - Amazon Simple Storage Service  
#       - https://docs.aws.amazon.com/AmazonS3/latest/userguide/configure-inventory.html
#   Enabling Amazon S3 server access logging - Amazon Simple Storage Service 
#       - https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html
# ------------------------------------------------------------------------------

Import-Module AWS.Tools.Common, AWS.Tools.S3

param (
  [Parameter(Mandatory = $true)]
  [string] $regionId,

  [Parameter(Mandatory = $true)]
  [string] $awsProfile,

  [Parameter(Mandatory = $true)]
  [string] $analyticsBucket,

  [Parameter(Mandatory = $false)]
  [int] $retainForDays = 90,

  [Parameter(ParameterSetName = 'Analytics', Mandatory = $false)]
  [Switch] $Analytics = $true,

  [Parameter(ParameterSetName = 'S3Inv', Mandatory = $false)]
  [Switch] $S3Inv = $true
)

# Create Analytics Bucket
New-S3Bucket -ProfileName $awsProfile -BucketName $analyticsBucket -Region $regionId -ObjectLockEnabledForBucket $true

# Configure bucket policy for the destination bucket:

$policy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "InventoryAndLoggingBucketPolicy",
            "Effect": "Allow",
            "Principal": {
                "Service": "s3.amazonaws.com"
            },
            "Action": [
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::$analyticsBucket/*",
            "Condition": {
                "ArnLike": {
                    "aws:SourceArn": "arn:aws:s3:::*"
                },
                "StringEquals": {
                    "aws:SourceAccount": "$awsAccountId"
                }
            }
        }
    ]
}
"@

Write-S3BucketPolicy -ProfileName $awsProfile -BucketName $analyticsBucket -Policy $policy

# Configure bucket lifecycle policy for the destination bucket so all items expire

$ExpireRule = [Amazon.S3.Model.LifecycleRule] @{
    Id =  "Remove-in-days"
    Status = "Enabled"
    Expiration =  @{
        Days = $retainForDays
    }
    NoncurrentVersionExpiration = @{
        NoncurrentDays = $retainForDays
    }
    Filter = @{}
}

Write-S3LifecycleConfiguration -ProfileName $awsProfile -BucketName $analyticsBucket -Configuration_Rule $ExpireRule

# List all S3 buckets and enable S3 Inventory and Logging

$buckets = Get-S3Bucket -ProfileName $awsProfile | Select-Object -ExpandProperty BucketName

foreach ($bucket in $buckets) {
  If($S3Inv){
    $inventoryConfig = @{
        ProfileName = $awsProfile
        BucketName = "arn:aws:s3:::$bucket"
        InventoryId = "1111S3Inventory"
        InventoryConfiguration_InventoryId = "1111S3Inventory"
        InventoryConfiguration_IsEnabled = $true        
        S3BucketDestination_BucketName = $analyticsBucket
        S3BucketDestination_Prefix = "inventory-reports/"
        S3BucketDestination_InventoryFormat = "CSV"
        InventoryConfiguration_IncludedObjectVersion = "All"
        Schedule_Frequency = "Weekly"
    }

    Write-S3BucketInventoryConfiguration @inventoryConfig
  }

  If($Analytics) {
    $loggingConfig = @{
        ProfileName = $awsProfile
        BucketName = $bucket
        LoggingConfig_TargetBucketName = $analyticsBucket
        LoggingConfig_TargetPrefix = "access-logs/"
    }
    
    Write-S3BucketLogging @loggingConfig
  }
}

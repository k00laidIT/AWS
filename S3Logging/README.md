# s3-invandlogging.ps1

#### Purpose: 
Within a given AWS account will enable access loging and/or s3 inventory service to write to a provided bucket for any buckets within that account

#### Prerequisites:
  1. Ensure you have the AWS Tools for PowerShell installed and configured with appropriate credentials.
  2. Identify a destination bucket for storing inventory reports and access logs.
  3. Make sure you have the necessary permissions to modify bucket configurations.

#### Verify configuration:
 * Check inventory configuration for a sample bucket:
       Get-S3BucketInventoryConfiguration -BucketName "sample-bucket-name" -Id "InventoryConfig"
 *  Check logging configuration for a sample bucket:
       Get-S3BucketLogging -BucketName "sample-bucket-name"

#### Usage:
./s3-invandlogging.ps1 -regionId "us-east-2" `
   -awsProfile "myAWSProfile" `
   -analyticsBucket "us-east-2-myaccount-analytics1" `
   -retainForDays "90" `
   -Analytics -S3Inv

#### Sources
*   Configuring Amazon S3 Inventory - Amazon Simple Storage Service  
       - https://docs.aws.amazon.com/AmazonS3/latest/userguide/configure-inventory.html
*   Enabling Amazon S3 server access logging - Amazon Simple Storage Service 
       - https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html

#!/bin/bash

# --- Script to upload content to the Dev S3 bucket ---

# 1. Get the S3 bucket name from the Terraform state
BUCKET_NAME=$(terraform output -raw static_site_bucket_name)

# Note: If the output 'static_site_bucket_name' is missing,
# we use the known name: fivexl-dev-static-site-content

if [ -z "$BUCKET_NAME" ]; then
    BUCKET_NAME="fivexl-dev-static-site-content"
fi

# 2. Upload the index.html file to the S3 bucket root
echo "Uploading index.html to s3://${BUCKET_NAME} using profile dev-account..."

aws s3 cp index.html "s3://${BUCKET_NAME}/" --profile dev-account

echo "Upload complete."

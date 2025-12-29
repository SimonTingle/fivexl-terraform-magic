# 📘 Serverless Static Website: Operational Runbook

This document provides a comprehensive guide to configuring, deploying, and managing the serverless static website infrastructure on AWS using Terraform.

---

## 1. Configuration: Understanding `terraform.tfvars`

Before running any commands, it is crucial to understand how we pass settings to Terraform. We use a file named `terraform.tfvars` to separate our **configuration (data)** from our **infrastructure code (logic)**.

### Why do we use it?

Hardcoding values (like bucket names) inside `main.tf` makes the code brittle and hard to reuse. By using `terraform.tfvars`, we can use the exact same code for both **Dev** and **Prod** environments simply by feeding it a different variables file.

### Inside Your `terraform.tfvars`

Open `serverless-static/environments/dev/terraform.tfvars`. You will see settings similar to this:

```hcl
# 1. Bucket Name Prefix
# We define a prefix instead of a full name to ensure uniqueness.
# Terraform will create a bucket like: "fivexl-dev-static-site-content"
bucket_name_prefix = "fivexl-dev-static-site"

# 2. Resource Tags
# These tags are automatically applied to every resource (Bucket, CloudFront, etc.)
# This helps with cost tracking and organization in the AWS Console.
tags = {
  Environment = "dev"
  Project     = "static-website-task"
  ManagedBy   = "Terraform"
}
```

* **To change the website name:** Edit `bucket_name_prefix`.
* **To change billing labels:** Edit the `tags` block.

---

## 2. Deployment Workflow

Follow these steps strictly to deploy the infrastructure.

### 📍 Step 1: Navigate to the Environment

Terraform commands must be run from the specific environment directory.

```bash
cd serverless-static/environments/dev
```

### ⚙️ Step 2: Initialize Project

Downloads AWS providers and configures the remote S3 backend for state storage.

```bash
terraform init -backend-config="profile=dev-account"
```

### 🔍 Step 3: Plan (Preview)

Checks the configuration against the real world and shows you what will be created.

```bash
terraform plan -var-file="terraform.tfvars"
```

### 🚀 Step 4: Apply (Deploy)

Provisions the actual resources in AWS (S3, CloudFront, OAC).

```bash
terraform apply -var-file="terraform.tfvars" --auto-approve
```

**Expected Output:**
```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
website_url = "dyk00m6qegbao.cloudfront.net"
```

⚠️ **Note:** Copy the `website_url` from the output. You will need it to view your site.

---

## 3. Content Management

Terraform builds the empty infrastructure ("the house"). We use a script to move the content ("the furniture") in.

### 📤 Step 5: Upload Website Content

This script uses the AWS CLI to sync your local `index.html` to the S3 bucket.

```bash
# 1. Make the script executable (only required once)
chmod +x update_content.sh

# 2. Run the upload script
./update_content.sh
```

### ✅ Step 6: Verify Deployment

Open your web browser and navigate to the CloudFront URL you copied in Step 4 (e.g., `https://dyk00m6qegbao.cloudfront.net`).

---

## 4. Teardown & Cleanup

To avoid incurring costs for the CloudFront distribution or S3 storage when not in use, follow this cleanup procedure.

### 🧹 Step 7: Destroy Infrastructure

**Important:** Terraform cannot delete a non-empty S3 bucket if versioning is enabled. You must manually empty it first.

1. **Empty the S3 Bucket:**

```bash
aws s3 rm s3://fivexl-dev-static-site-content --recursive --profile dev-account
```

2. **Destroy Terraform Resources:**

```bash
terraform destroy -var-file="terraform.tfvars" --auto-approve
```

3. **Verification:**

Ensure the command outputs: `Destroy complete! Resources: 5 destroyed.`

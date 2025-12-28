Here is the refined technical development log, focusing exclusively on the application creation, infrastructure provisioning, and error resolution process.

# 🛠️ Technical Development Log: Serverless Static Website

**Project:** fivexl-tf-task
**Stack:** Terraform, AWS (S3, CloudFront, DynamoDB), Bash

---

## Phase 1: Initialization and Backend Configuration

**Step 1: Define Backend Configuration**
I configured the `main.tf` to use the `s3` backend for remote state storage and `dynamodb` for state locking.

**Step 2: Initialize Terraform**
I ran the initialization command to download providers and configure the backend.

> **Command:** `terraform init`

**❌ Error 1: Credential/Profile Missing**
Terraform failed to authenticate with AWS because no credentials were provided in the environment or command.

> **Fix:** I modified the command to explicitly use the AWS CLI profile created for this project.
> **Revision:** `terraform init -backend-config="profile=dev-account"`

**❌ Error 2: Backend Resources Missing**
The initialization failed because the specified S3 bucket and DynamoDB table did not exist in AWS. Terraform cannot create its own backend state resources during initialization.

> **Fix:** I manually created the infrastructure prerequisites using the AWS Console/CLI:
> * **S3 Bucket:** `fivexl-tf-state-bucket` (Versioned, Encrypted)
> * **DynamoDB Table:** `fivexl-task-tf-lock-table` (Partition Key: `LockID`)
> 
> 
> **Result:** `terraform init` succeeded.

---

## Phase 2: Core Infrastructure Deployment (Terraform Apply)

**Step 3: First Apply Attempt**
I attempted to provision the actual resources (S3 Static Site module).

> **Command:** `terraform apply --auto-approve`

**❌ Error 3: Variable Scope Conflict**
I received an "Unsupported Argument" error. The root `main.tf` contained `variable` blocks that conflicted with the separate `variables.tf` file, causing duplication and scope confusion.

> **Fix:** I removed the redundant `variable` blocks from `main.tf`, ensuring definitions lived strictly in `variables.tf`.

**❌ Error 4: Module Input Failure**
Even after cleaning the root files, the child module (`modules/s3-static-site`) rejected the arguments.

> **Fix:** I updated the module's internal `variables.tf` to explicitly accept `bucket_name_prefix` and `tags`, allowing values to pass from the root to the module.

**Step 4: Loading Variable Values**
Terraform prompted for variables interactively, which is not suitable for automation.

> **Fix:** I explicitly passed the variable definitions file in the command.
> **Revision:** `terraform apply -var-file="terraform.tfvars" --auto-approve`

---

## Phase 3: Module Logic and Outputs

**Step 5: Output Configuration**
I attempted to output the final Website URL to the console after deployment.

**❌ Error 5: Reference to Undeclared Resource**
The root `outputs.tf` tried to reference a CloudFront resource that existed only *inside* the module, which is not visible to the root.

> **Fix:** I updated the root `outputs.tf` to reference the module's output instead: `value = module.static_website.website_url`.

**❌ Error 6: Unsupported Attribute**
The module was not exporting the `website_url` attribute, causing the root reference to fail.

> **Fix:** I updated the module's `outputs.tf` to explicitly expose the CloudFront Domain Name.

---

## Phase 4: Successful Deployment and Content Upload

**Step 6: Final Infrastructure Apply**

> **Command:** `terraform apply -var-file="terraform.tfvars" --auto-approve`
> **Result:** **Success.** 5 Resources created (S3 Bucket, OAC, CloudFront Distribution, Bucket Policy, Versioning).
> **Output:** `dyk00m6qegbao.cloudfront.net`

**Step 7: Content Upload**
I wrote a bash script (`update_content.sh`) to upload `index.html` to the newly created bucket.

**❌ Error 7: ACL Not Supported**
The upload failed with `AccessControlListNotSupported`. The script used the `--acl public-read` flag, but the bucket was configured with "Bucket Owner Enforced" (ACLs disabled) for security.

> **Fix:** I modified the script to remove the `--acl public-read` flag, relying on the Bucket Policy and OAC for access instead.
> **Command:** `./update_content.sh`
> **Result:** **Success.** Content uploaded.

---

## Phase 5: Infrastructure Teardown (Cost Management)

**Step 8: Destroy Resources**
To verify cleanup and stop costs, I initiated the destroy process.

> **Command:** `terraform destroy --auto-approve`

**❌ Error 8: Bucket Not Empty**
Terraform deleted the CloudFront distribution but failed to delete the S3 bucket.

> **Error Message:** `api error BucketNotEmpty: The bucket you tried to delete is not empty.`
> **Cause:** The bucket had Versioning enabled. Terraform deleted the *infrastructure*, but the *data* (versions of `index.html`) persisted, blocking bucket deletion.

**Step 9: Force Clean Bucket**
I had to manually empty the bucket using the AWS CLI.

> **Command:** `aws s3 rm s3://fivexl-dev-static-site-content --recursive --profile dev-account`

**Step 10: Final Destroy**

> **Command:** `terraform destroy --auto-approve`
> **Result:** **Success.** All infrastructure removed.

---

## Phase 6: Architecture Documentation (Rationale)

**Step 11: Drafting the RATIONALE.md**
I needed to satisfy the requirement to compare two hosting methods. I drafted a comparison between **Serverless** (S3+CloudFront) and **Containerized** (ECS Fargate).

**Step 12: Appending the Glossary**
I attempted to append a technical glossary to the file using a heredoc (`cat << EOF`).

**❌ Error 9: Shell Execution in Text**
The shell attempted to execute words wrapped in backticks (e.g., ``terraform.tfstate``) inside the text block, causing "command not found" errors.

> **Fix:** I quoted the heredoc delimiter (`cat << 'EOF'`) to prevent the shell from interpreting the text as code.

**Step 13: Finalizing Documentation**
The `RATIONALE.md` was successfully written with the Architecture Decision Record and the Technical Glossary.

## 📝 Project Retrospective: Deploying the Serverless Static Website

This document serves as a detailed record of the project, documenting every step, error, and revision I encountered while deploying the static website infrastructure using Terraform.

### Phase 1: Initial Setup and Backend Configuration

My first major task was to initialize the Terraform environment and correctly configure the S3 backend for state locking.

1.  **I Installed** the necessary AWS provider and configured the S3 backend settings in `main.tf` to store the Terraform state remotely. I defined the bucket name, key path, region, encryption, and the DynamoDB table for state locking.
2.  **I Ran `terraform init`** for the first time.
3.  **Error 1: Credential Issue.** I received an error stating the S3 bucket or DynamoDB table did not exist, indicating a permissions or configuration failure.
4.  **Revision 1 (Authentication Fix):** I realized I had not specified which AWS profile to use for the initialization. **I modified the command** to explicitly use my `dev-account` profile:
    ```bash
    terraform init -backend-config="profile=dev-account"
    ```
5.  **Error 2: Backend Structure (S3/DynamoDB Missing).** The initialization failed because the backend resources (`fivexl-tf-state-bucket` and `fivexl-task-tf-lock-table`) were not yet created in AWS.
6.  **Revision 2 (Manual Backend Creation):** Since Terraform cannot create the backend resources it relies on *during* initialization, **I manually created** the S3 bucket and the DynamoDB lock table using the AWS CLI or Console.
7.  **Success:** After manual creation, **I successfully ran `terraform init`**.

### Phase 2: Configuration Syntax and Variable Errors

With the backend initialized, I moved to the deployment phase (`terraform apply`).

1.  **I Attempted to Run `terraform apply --auto-approve`**. I was prompted interactively for `var.bucket_name_prefix` and `var.tags`. I entered the required values: `fivexl-dev-static-site` and the map tags.
2.  **Error 3: Unsupported Argument (Root Module).** After entering the values, I encountered the error: `An argument named "bucket_name_prefix" is not expected here` on `main.tf`. This was a confusion in variable scope.
3.  **Revision 3 (File Structure Clean-up):** I realized my `main.tf` file had duplicate `variable` blocks, which conflicted with the existing `variables.tf` file in the same directory. **I deleted the redundant `variable` blocks** from `main.tf`, leaving only the `terraform`, `provider`, and `module` blocks.
4.  **Error 4: Duplicate Variable Declaration.** I received the error: `A variable named "bucket_name_prefix" was already declared at main.tf...`. This confirmed I failed to fully remove the conflicting variable definitions during the previous revision.
5.  **Revision 4 (Forced File Write):** **I ran a sequence of `cat << EOF` commands** to guarantee that `main.tf` contained only the clean structure (no variable blocks) and that `variables.tf` contained only the unique variable definitions.
6.  **Error 5: Reverting to Unsupported Argument.** Despite the cleanup, I received the "Unsupported argument" error again, and the interactive prompt still appeared. This indicated my explicit variable file (`terraform.tfvars`) was not being loaded.
7.  **Revision 5 (Explicit Var-File):** **I corrected the apply command** to explicitly force the loading of my input file:
    ```bash
    terraform apply -var-file="terraform.tfvars" --auto-approve
    ```
8.  **Error 6: Module Argument Not Recognized.** Even with the correct file loading, the error persisted. The problem was not the root module, but the *child module* was not configured to accept the arguments.
9.  **Revision 6 (Module Variable Definition Fix):** **I navigated to the module directory** (`s3-static-site`) and **force-wrote the module's `variables.tf` file** to ensure the module explicitly declared `bucket_name_prefix` and `tags` as inputs.

### Phase 3: Module Logic and Output Errors

With the inputs finally flowing correctly to the module, I encountered issues with how the module's output was consumed.

1.  **Error 7: Reference to Undeclared Resource.** After a successful plan, the apply failed with: `A managed resource "aws_cloudfront_distribution" "s3_distribution" has not been declared in the root module`. This was because my environment's `outputs.tf` was trying to directly reference a resource *inside* the module.
2.  **Revision 7 (Environment Output Fix):** **I edited the environment's `outputs.tf`** to correctly reference the *module's output* instead of the internal resource: `value = module.static_website.website_url`.
3.  **Error 8: Unsupported Attribute.** The apply failed again: `This object does not have an attribute named "website_url"`. This meant I fixed the consumption, but the module itself was not exporting that output name.
4.  **Revision 8 (Module Output Fix):** **I navigated back to the module directory** and **force-wrote the module's `outputs.tf` file** to ensure it contained the required `website_url` output, pointing to the internal resource's domain name.

### Phase 4: Successful Deployment and Content Upload

Finally, with all configuration files aligned, the deployment succeeded.

1.  **Success:** **I ran `terraform apply --auto-approve` one final time**, and the plan executed successfully, creating 5 resources (S3, OAC, CloudFront, Policy, Versioning).
2.  **I Received the Output:** The public website URL: `dyk00m6qegbao.cloudfront.net`.
3.  **Error 9: Upload Script Missing.** When I tried to upload the content, the script `update_content.sh` was empty.
4.  **Revision 9 (Write Upload Script):** **I wrote the necessary `update_content.sh` script** containing the `aws s3 cp` command to transfer `index.html`.
5.  **Error 10: ACL Not Supported.** The upload failed with: `An error occurred (AccessControlListNotSupported) when calling the PutObject operation: The bucket does not allow ACLs`. This was because the S3 bucket's security settings blocked the old `--acl public-read` flag.
6.  **Revision 10 (Remove ACL Flag):** **I edited `update_content.sh`** and removed the `--acl public-read` flag.
7.  **Final Success:** **I ran `./update_content.sh`**, and the content uploaded successfully. The static website was live.

### Phase 5: Cleanup and Final Tasks

1.  **I Asked** about the running costs of the environment.
2.  **I Decided** to shut down the infrastructure temporarily to save money.
3.  **I Ran `terraform destroy --auto-approve`**.
4.  **Error 11: Bucket Not Empty.** The destroy failed with: `api error BucketNotEmpty: The bucket you tried to delete is not empty. You must delete all versions in the bucket.` This was because versioning was enabled, and the `index.html` file still existed as a version.
5.  **Revision 11 (Force Empty S3):** **I ran the AWS CLI command** to force empty the versioned S3 bucket:
    ```bash
    aws s3 rm s3://fivexl-dev-static-site-content --recursive --profile dev-account
    ```
6.  **Final Cleanup Success:** **I re-ran `terraform destroy --auto-approve`**, and all remaining resources were successfully deleted, concluding the project. I made sure to leave the S3 state backend and DynamoDB lock table intact for the next time I need to deploy.

**I am now confident that all files reflect the successful, stable, and correct infrastructure configuration.**

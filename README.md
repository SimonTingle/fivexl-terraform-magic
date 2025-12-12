# 🚀 FivexL Backend Role: Terraform Magic Task

This repository contains my solution to the Infrastructure as Code (IaC) challenge for the FivexL Back Office role application.

The goal of this task was to research and provision two distinct architectures for serving a website on AWS, using **Terraform** for all infrastructure setup, ensuring multi-environment deployment capability, and maintaining a static endpoint after redeployment.

## 🎯 Architecture Choices and Rationale (RATIONALE.md)

I have chosen two architectures that represent different real-world use cases, cost profiles, and deployment strategies:

| Architecture | Primary AWS Services | Use Case / Trade-offs |
| :--- | :--- | :--- |
| **1. Serverless Static Website** | S3, CloudFront, OAC | **High Scalability, Low Cost.** Ideal for static content, single-page applications (SPAs), marketing pages. Zero server management. |
| **2. Containerized Dynamic Website** | VPC, ECS Fargate, ALB, ECR | **Flexibility, Dynamic Content.** Ideal for complex backends, APIs, or websites requiring server-side logic (e.g., Node.js, Python/Django). Highly resilient and fault-tolerant. |

The detailed rationale, covering why these were chosen and how they meet the task requirements, is documented in the **`RATIONALE.md`** file.

---

## 🛠️ Project Structure and Multi-Account Deployment

The repository uses a standard **Terraform Module** structure to enable easy deployment across environments and accounts.

### Directory Structure

```
.
├── containerized-ecs/           # Architecture 2: ECS Fargate and ALB (Dynamic)
├── serverless-static/           # Architecture 1: S3 and CloudFront (Static)
│   ├── environments/            # Root modules for Dev/Prod
│   │   ├── dev/
│   │   └── prod/
│   └── modules/s3-static-site   # Reusable Terraform module for the website infra
└── RATIONALE.md                 # Detailed justification for architectural choices
```

### Multi-Account Capability

* The code is designed for true multi-account deployment.
* The `dev` and `prod` directories use different **AWS CLI profiles** (`dev-account` and `prod-account`) and separate **Terraform state keys** in the backend.
* **Parameter Differences:** Configuration files (`terraform.tfvars`) allow for different parameters (e.g., instance size, tags, unique bucket prefixes) to be passed to the same module for Dev vs. Prod.

---

## ⚙️ How to Test and Deploy (Serverless Static Demo)

The `serverless-static` architecture is fully set up for immediate testing.

### Prerequisites

1.  **AWS CLI Profiles:** You must have the AWS CLI installed and configured with two profiles: `dev-account` and `prod-account`.
2.  **Remote State Resources:** The following resources must be created in the target AWS account(s) before initialization:
    * **S3 Bucket:** `fivexl-tf-state-bucket` (Globally unique, Versioning Enabled)
    * **DynamoDB Table:** `fivexl-task-tf-lock-table` (Partition Key: `LockID`, Type: String)

### Step 1: Initialize the Dev Environment

Run this from the **`serverless-static/environments/dev/`** directory to connect to the S3 backend using the `dev-account` credentials.

```bash
cd serverless-static/environments/dev/
terraform init -backend-config="profile=dev-account"
```

### Step 2: Review and Apply the Infrastructure

Run a plan to see the S3 bucket, CloudFront distribution, and related security resources being created.

```bash
terraform plan
terraform apply
```

### Step 3: Deployment and Redeployment (Fulfilling Task Requirement)

* The public URL will be visible in the output: `outputs.website_url`.
* **Redeployment Test:** Changes to the HTML cause a **redistribution**, but the **CloudFront DNS name remains static**, fulfilling the requirement.
    1.  Create an `index.html` file.
        ```bash
        echo "<h1>Hello FivexL - Dev Deployment 1</h1>" > index.html
        ```
    2.  Upload the file to the S3 bucket (you will need the S3 bucket name from the state/console).
        ```bash
        aws s3 cp index.html s3://[S3_BUCKET_NAME]/ --profile dev-account
        ```
    3.  Run an **invalidation** command against the CloudFront distribution to force content refresh (you will need the CloudFront ID from the state/console).
        ```bash
        aws cloudfront create-invalidation --distribution-id [CF_ID] --paths "/*" --profile dev-account
        ```

### Step 4: Deploy the Prod Environment

To demonstrate multi-environment capability, run the same commands from the Prod directory (assuming you have repeated the setup for the `prod-account` profile):

```bash
cd ../prod/
terraform init -backend-config="profile=prod-account"
terraform apply
```

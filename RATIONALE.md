# Architecture Decision Record: Static Website Hosting

## Context
The objective was to architect and deploy a solution for hosting a static HTML website on AWS. The requirements emphasized automation (Terraform), remote state management, stable endpoints, and multi-account support.

Two primary architectural approaches were researched and evaluated:
1.  **Serverless Static Hosting:** Amazon S3 + Amazon CloudFront.
2.  **Containerized Hosting:** Amazon ECS (Fargate) + Application Load Balancer (ALB).

---

## Option 1: Serverless Static Hosting (Selected)
**Architecture:** S3 Bucket (Storage) → CloudFront (CDN & TLS) → End User.

### Reasons for Selection
* **Cost Efficiency:** This is the most cost-effective solution on AWS. You only pay for storage and data transfer (requests). There is no "idle" cost when no one is visiting the site.
* **Operational Overhead:** Zero. There are no servers to patch, no operating systems to manage, and no containers to orchestrate.
* **Performance:** CloudFront caches content at the edge (globally), providing lower latency than a single region container.
* **Security:** CloudFront Origin Access Control (OAC) ensures the S3 bucket is private and only accessible via the CDN.

### Limitations
* Cannot execute server-side code (PHP, Python, etc.), which is acceptable for this static site requirement.

---

## Option 2: Containerized Hosting (Rejected)
**Architecture:** Docker Container (Nginx) → ECS Fargate → Application Load Balancer → End User.

### Reasons for Rejection
* **Cost Prohibitive:** This solution requires an Application Load Balancer (approx. $16/month minimum) and Fargate tasks running 24/7, even with zero traffic. This is financial overkill for a simple HTML file.
* **Unnecessary Complexity:** Requires a full VPC networking stack (Subnets, Route Tables, Internet Gateways, Security Groups) and complex IAM roles.
* **Maintenance:** While "Serverless" in compute, Fargate still requires managing container images, health checks, and scaling policies.

---

## Final Decision
I chose **Option 1 (S3 + CloudFront)** because it adheres to the **"Serverless First"** best practice for static content. It fulfills all technical requirements (Stable Endpoint, TLS, Auto-Redeployment capability) while minimizing cost and complexity, allowing for a strictly Infrastructure-as-Code deployment without the need for VPC networking overhead.

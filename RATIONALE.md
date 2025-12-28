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

---

## 📚 Technical Glossary

### Infrastructure Components
* **Amazon S3 (Simple Storage Service):** An object storage service offering industry-leading scalability, data availability, security, and performance. In this project, it serves as the "Origin," hosting the raw HTML and asset files.
* **Amazon CloudFront:** A global Content Delivery Network (CDN) that caches content at Edge Locations closer to the user. It handles TLS/SSL termination (HTTPS) and reduces latency by serving the cached S3 content from the nearest physical location to the visitor.
* **OAC (Origin Access Control):** A modern security feature for CloudFront that restricts access to the S3 bucket. It ensures that users cannot bypass the CDN to access files directly from S3, enforcing security policies and traffic flow.
* **Amazon DynamoDB:** A serverless, NoSQL key-value database. In this architecture, it is strictly used for **State Locking**. It creates a specific record when Terraform is running to prevent multiple developers (or CI pipelines) from modifying the infrastructure simultaneously, protecting against corruption.

### Terraform Concepts
* **Infrastructure as Code (IaC):** The practice of managing and provisioning computer data centers through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools.
* **Remote State (Backend):** By default, Terraform stores state locally (). For production/team environments, this state is stored remotely (in our case, an S3 bucket). This ensures the "source of truth" regarding the infrastructure is shared and durable.
* **State Locking:** A mechanism that prevents concurrent operations on the Terraform state. If User A runs , the lock table prevents User B from running it at the same time, avoiding race conditions and state file corruption.
* **Modules:** Self-contained packages of Terraform configurations that are managed as a group. This project uses a modular design () to encapsulate the logic for the website, making the code reusable across different environments (Dev/Prod) with different inputs.
* **Profiles:** Named configurations in the AWS CLI that contain credentials for specific accounts. This project leverages profiles () to safely switch deployment targets between development and production AWS accounts without hardcoding credentials.

---

## 📚 Technical Glossary

### Infrastructure Components
* **Amazon S3 (Simple Storage Service):** An object storage service offering industry-leading scalability, data availability, security, and performance. In this project, it serves as the "Origin," hosting the raw HTML and asset files.
* **Amazon CloudFront:** A global Content Delivery Network (CDN) that caches content at Edge Locations closer to the user. It handles TLS/SSL termination (HTTPS) and reduces latency by serving the cached S3 content from the nearest physical location to the visitor.
* **OAC (Origin Access Control):** A modern security feature for CloudFront that restricts access to the S3 bucket. It ensures that users cannot bypass the CDN to access files directly from S3, enforcing security policies and traffic flow.
* **Amazon DynamoDB:** A serverless, NoSQL key-value database. In this architecture, it is strictly used for **State Locking**. It creates a specific record when Terraform is running to prevent multiple developers (or CI pipelines) from modifying the infrastructure simultaneously, protecting against corruption.

### Terraform Concepts
* **Infrastructure as Code (IaC):** The practice of managing and provisioning computer data centers through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools.
* **Remote State (Backend):** By default, Terraform stores state locally (`terraform.tfstate`). For production/team environments, this state is stored remotely (in our case, an S3 bucket). This ensures the "source of truth" regarding the infrastructure is shared and durable.
* **State Locking:** A mechanism that prevents concurrent operations on the Terraform state. If User A runs `terraform apply`, the lock table prevents User B from running it at the same time, avoiding race conditions and state file corruption.
* **Modules:** Self-contained packages of Terraform configurations that are managed as a group. This project uses a modular design (`modules/s3-static-site`) to encapsulate the logic for the website, making the code reusable across different environments (Dev/Prod) with different inputs.
* **Profiles:** Named configurations in the AWS CLI that contain credentials for specific accounts. This project leverages profiles (`dev-account`) to safely switch deployment targets between development and production AWS accounts without hardcoding credentials.

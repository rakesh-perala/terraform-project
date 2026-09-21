# ShopSphere Enterprise DevOps Project

## Enterprise AWS DevOps Project — Terraform + Jenkins + AWS + CI/CD

> **Purpose of this README:**
> This README is the complete teaching and recording guide for the ShopSphere Enterprise DevOps project.
>
> It documents the project **point by point from the beginning up to the current completed milestone**.
>
> We will continue updating this README as the project progresses.

---

# 1. Project Overview

This project demonstrates how a real enterprise DevOps team can separate:

1. **Platform / Core Infrastructure**
2. **Application Infrastructure**
3. **Application CI/CD**

Instead of putting everything into one Terraform repository, we are using **two repositories**.

```text
                         GitHub
                           |
             +-------------+-------------+
             |                           |
             v                           v
       Repository 1                 Repository 2
       Platform / Core              Application
       Infrastructure               + App Infrastructure
             |                           |
             |                           |
       Terraform                     Java Application
             |                       Terraform
             |                       Jenkinsfiles
             |                       Tomcat
             |                       SonarQube
             |                       Nexus
             |
             v
       AWS VPC
       Subnets
       Networking
       Jenkins
```

---

# 2. Business Scenario

Imagine a company called:

```text
CloudNova Technologies
```

The company is developing an application called:

```text
ShopSphere
```

ShopSphere is a Java-based enterprise application.

The DevOps team needs:

* AWS networking
* VPC
* Public and private subnets
* NAT Gateway
* Jenkins
* Tomcat
* SonarQube
* Nexus
* Terraform
* CI/CD
* Security Groups
* IAM
* Remote Terraform state
* Application deployment

The organization does not want developers modifying the core platform infrastructure every time they deploy application code.

Therefore, infrastructure ownership is separated.

---

# 3. Repository Strategy

We use exactly **two repositories**.

## Repository 1

```text
terraform-project
```

GitHub:

```text
https://github.com/rakesh-perala/terraform-project.git
```

Purpose:

```text
Platform / Core Infrastructure
```

It owns:

* VPC
* Subnets
* Route tables
* Internet Gateway
* NAT Gateway
* Jenkins EC2
* Jenkins Security Group
* Jenkins IAM Role
* Jenkins Instance Profile

---

# 4. Repository 2

Repository 2 will contain:

```text
ShopSphere Application
+
Application Infrastructure
```

It will eventually contain:

```text
Java Application
Jenkinsfile
Infrastructure Jenkinsfile
Tomcat Terraform
Tools EC2 Terraform
Tomcat Security Group
Tools Security Group
Tomcat user-data
SonarQube
Nexus
Docker Compose
```

Repository 2 will **not create another VPC**.

Instead, it consumes the VPC and subnet information created by Repository 1.

---

# 5. Why Two Repositories?

A common beginner approach is:

```text
One repository
    |
    +-- VPC
    +-- Jenkins
    +-- Tomcat
    +-- SonarQube
    +-- Nexus
    +-- Application
```

This creates strong coupling.

Instead, we use:

```text
Repository 1
Platform
    |
    +-- VPC
    +-- Networking
    +-- Jenkins
```

and:

```text
Repository 2
Application
    |
    +-- Tomcat
    +-- SonarQube
    +-- Nexus
    +-- Java Application
```

The relationship becomes:

```text
Repository 1
     |
     | Terraform Remote State
     |
     v
Repository 2
```

Repository 2 consumes only the required outputs from Repository 1.

---

# 6. High-Level Enterprise Architecture

```text
                         GitHub
                           |
             +-------------+-------------+
             |                           |
             v                           v
      terraform-project           application-devops
      Repository 1                Repository 2
             |                           |
             |                           |
             v                           |
       Terraform                         |
             |                           |
      +------+-------+                   |
      |              |                   |
      v              v                   |
     VPC           Jenkins                |
      |              |                   |
      |              |                   |
      |              +-------------------+
      |                  Infrastructure Pipeline
      |
      +-- Public Subnet
      |      |
      |      +-- Jenkins EC2
      |
      +-- Private Subnet
             |
             +-- Tomcat
             |
             +-- Tools EC2
                    |
                    +-- SonarQube
                    |
                    +-- Nexus
```

---

# 7. Current AWS Region

The project is currently running in:

```text
ap-south-1
```

AWS account:

```text
652310866649
```

---

# 8. Repository 1 — Current Status

Repository:

```text
terraform-project
```

Local directory:

```text
~/lab/terraform-project/terraform
```

Current Terraform structure:

```text
terraform/
├── backend.tf
├── jenkins-ec2.tf
├── jenkins-security-group.tf
├── jenkins-variables.tf
├── jenkins-iam.tf
├── main.tf
├── modules/
├── outputs.tf
├── providers.tf
├── terraform.tfvars
├── variables.tf
├── versions.tf
└── ...
```

---

# 9. File Responsibilities

## backend.tf

Responsible for Terraform remote state configuration.

Current backend:

```hcl
terraform {
  backend "s3" {
    bucket       = "shopsphere-terraform-state-652310866649"
    key          = "platform/dev/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}
```

---

# 10. Why Remote State?

Terraform needs to remember:

```text
What resources does Terraform manage?
```

This information is stored in:

```text
terraform.tfstate
```

Instead of keeping this state only on one developer laptop, enterprise teams normally centralize it.

Our state is stored in:

```text
Amazon S3
```

Bucket:

```text
shopsphere-terraform-state-652310866649
```

State key:

```text
platform/dev/terraform.tfstate
```

Architecture:

```text
Developer / Jenkins
        |
        v
    Terraform
        |
        v
       S3
        |
        +-- platform/dev/terraform.tfstate
```

---

# 11. Terraform State Locking

We use:

```hcl
use_lockfile = true
```

This prevents multiple Terraform executions from modifying the same state simultaneously.

Example:

```text
Jenkins Pipeline A
        |
        | Terraform Apply
        v
      State Lock
        |
        X
Jenkins Pipeline B
cannot modify the same state
```

After the operation finishes:

```text
Terraform Apply
      |
      v
Lock released
```

---

# 12. State Migration

Initially the Terraform state was local.

We migrated it to S3 using:

```bash
terraform init -migrate-state
```

Terraform successfully migrated the state.

This is important because:

```text
Local State
    |
    | migrate-state
    v
S3 Remote State
```

We did not manually recreate the infrastructure.

---

# 13. Important Terraform Concept

Do not confuse:

```text
Terraform configuration
```

with:

```text
Terraform state
```

Configuration:

```text
What infrastructure should exist?
```

State:

```text
What infrastructure Terraform currently manages?
```

AWS:

```text
What actually exists?
```

Terraform compares all three.

```text
Terraform Configuration
          |
          |
          v
    Terraform State
          |
          |
          v
        AWS
```

This is the foundation of Terraform drift detection.

---

# 14. providers.tf

The provider configures Terraform to communicate with AWS.

Current project region:

```text
ap-south-1
```

Conceptually:

```text
Terraform
   |
   v
AWS Provider
   |
   v
AWS API
```

---

# 15. versions.tf

This file controls Terraform/provider version requirements.

Why?

Because enterprise projects should avoid unexpected provider upgrades.

Example concept:

```text
Terraform
   |
   +-- Required version
   |
   +-- AWS provider version
```

This provides predictable infrastructure builds.

---

# 16. main.tf

The root Terraform configuration connects the infrastructure modules/resources.

The VPC is handled through the VPC module.

Conceptually:

```text
Root Module
    |
    v
VPC Module
    |
    +-- VPC
    +-- Public Subnets
    +-- Private Subnets
    +-- IGW
    +-- NAT Gateway
    +-- Route Tables
```

---

# 17. Terraform Module Concept

A module is a reusable Terraform component.

Instead of writing everything in one file:

```text
main.tf
1000 lines
```

we can separate responsibilities.

Example:

```text
modules/
└── vpc/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

The root module calls the child module.

```text
Root Module
     |
     v
Child VPC Module
     |
     +-- VPC
     +-- Subnets
     +-- Routing
```

---

# 18. Root Module vs Child Module

## Root Module

The directory where Terraform commands are executed.

Example:

```bash
cd ~/lab/terraform-project/terraform
terraform plan
```

This directory is the root module.

---

## Child Module

A reusable module called by the root module.

Example:

```text
modules/vpc
```

Relationship:

```text
Root Module
     |
     | module "vpc"
     v
Child VPC Module
```

---

# 19. Jenkins Infrastructure

Repository 1 also creates Jenkins.

Jenkins is our CI/CD automation server.

Architecture:

```text
AWS
 |
 +-- VPC
      |
      +-- Public Subnet
            |
            +-- Jenkins EC2
```

Current Jenkins instance:

```text
Instance ID:
i-0dccda1a62dd6417a
```

---

# 20. Jenkins EC2 Details

Current state:

```text
State: running

Public IP:
43.205.215.230

Private IP:
10.0.1.137

Subnet:
subnet-07ad0a97aa7df9be8

Security Group:
sg-0dfadc1b44ab161ec
```

Instance type:

```text
t3.medium
```

Root volume:

```text
30 GB
gp3
encrypted
```

---

# 21. Jenkins Operating System

Jenkins is running on:

```text
Ubuntu 24.04 LTS
```

The EC2 instance is created through Terraform.

Therefore:

```text
Terraform
   |
   v
EC2
   |
   v
Ubuntu
   |
   v
Jenkins
```

---

# 22. Jenkins Bootstrap

Jenkins is installed automatically through Terraform `user_data`.

The bootstrap installs/configures:

```text
Java 21
Java 17 JDK
Maven
Docker
Docker Compose
Trivy
Git
Jenkins
AWS CLI
```

Some tools were additionally installed/validated manually during this lab.

---

# 23. Why user_data?

Instead of manually logging into EC2 and installing everything:

```text
SSH
apt install
configure
restart
```

Terraform can bootstrap the machine.

Architecture:

```text
Terraform
   |
   v
EC2
   |
   +-- user_data
          |
          +-- Install Java
          +-- Install Maven
          +-- Install Docker
          +-- Install Trivy
          +-- Install Jenkins
```

This makes the server reproducible.

---

# 24. Jenkins IAM Architecture

One of the most important parts of this project is AWS authentication.

We created:

```text
IAM Role
```

named:

```text
shopsphere-jenkins-role
```

and:

```text
Instance Profile
```

named:

```text
shopsphere-jenkins-profile
```

Architecture:

```text
Jenkins EC2
     |
     v
Instance Profile
shopsphere-jenkins-profile
     |
     v
IAM Role
shopsphere-jenkins-role
     |
     v
AWS STS
     |
     v
Temporary Credentials
```

---

# 25. Why Instance Profile?

We do NOT want:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

hardcoded on the Jenkins server.

Bad architecture:

```text
Jenkins
   |
   +-- access key
   +-- secret key
```

Better architecture:

```text
Jenkins EC2
      |
      v
IAM Instance Profile
      |
      v
IAM Role
      |
      v
Temporary AWS Credentials
```

This is the AWS-recommended role-based approach.

---

# 26. Jenkins IAM Authentication Validation

From inside Jenkins EC2 we executed:

```bash
aws sts get-caller-identity
```

Actual result:

```json
{
    "UserId": "AROAZPYGB5LMS5EOWVDFA:i-0dccda1a62dd6417",
    "Account": "652310866649",
    "Arn": "arn:aws:sts::652310866649:assumed-role/shopsphere-jenkins-role/i-0dccda1a62dd6417a"
}
```

The important line is:

```text
assumed-role/shopsphere-jenkins-role/
```

This proves Jenkins is using the EC2 IAM role.

---

# 27. Authentication vs Authorization

This is an important interview concept.

## Authentication

Question:

```text
Who are you?
```

Our Jenkins successfully proves:

```text
I am using shopsphere-jenkins-role
```

Authentication:

```text
PASS
```

---

## Authorization

Question:

```text
What are you allowed to do?
```

Currently the Jenkins IAM role does not have broad AWS permissions.

Therefore:

```text
Authentication = configured
Authorization = intentionally not fully granted yet
```

This is important.

We should NOT immediately attach:

```text
AdministratorAccess
```

Instead, later we will create a least-privilege policy based on the exact Terraform resources Repo 2 needs.

---

# 28. Why Not AdministratorAccess?

A common beginner solution:

```text
Jenkins
   |
   +-- AdministratorAccess
```

This is dangerous.

If Jenkins is compromised, the attacker could potentially control the AWS account.

Better:

```text
Jenkins
   |
   v
Least Privilege IAM Policy
   |
   +-- EC2 permissions required
   +-- Security Group permissions required
   +-- S3 state access
   +-- other exact required permissions
```

We will implement this after Repo 2 Terraform is defined, because the exact required permissions should be based on actual resources.

---

# 29. Jenkins Security Group

Current Jenkins Security Group:

```text
sg-0dfadc1b44ab161ec
```

Current inbound access is restricted.

SSH:

```text
TCP 22
Source:
106.66.38.177/32
```

Jenkins UI:

```text
TCP 8080
Source:
106.66.38.177/32
```

Outbound:

```text
All traffic
```

---

# 30. Why Restrict Jenkins Access?

We should avoid:

```text
0.0.0.0/0
```

for Jenkins administration.

Instead:

```text
Internet
    |
    v
User Public IP
106.66.38.177
    |
    v
Jenkins Security Group
    |
    +-- SSH 22
    +-- Jenkins 8080
```

Only the required source is allowed.

---

# 31. Important Public IP Note

The current public IP used for administration is:

```text
106.66.38.177
```

It is configured as:

```text
106.66.38.177/32
```

This means exactly one IPv4 address is allowed.

If the user's public IP changes:

```text
Current IP
    |
    X
Security Group blocks access
```

Then `terraform.tfvars` must be updated and Terraform applied.

---

# 32. AWS Network Architecture

Current VPC:

```text
VPC CIDR:

10.0.0.0/16
```

VPC ID:

```text
vpc-04066adbef1f771f5
```

Architecture:

```text
                     VPC
                10.0.0.0/16
                      |
        +-------------+-------------+
        |                           |
        v                           v
 Public Subnets              Private Subnets
        |                           |
        |                           |
   Jenkins EC2                Future Services
        |                    Tomcat / Tools
        |
       IGW
        |
    Internet
```

---

# 33. Availability Zones

The network spans two Availability Zones:

```text
ap-south-1a
ap-south-1b
```

This provides a basic multi-AZ architecture.

---

# 34. Public Subnets

Public subnet 1:

```text
10.0.1.0/24
```

AZ:

```text
ap-south-1a
```

Subnet ID:

```text
subnet-07ad0a97aa7df9be8
```

---

Public subnet 2:

```text
10.0.2.0/24
```

AZ:

```text
ap-south-1b
```

Subnet ID:

```text
subnet-0ae4782bcabba3a67
```

---

# 35. Private Subnets

Private subnet 1:

```text
10.0.11.0/24
```

AZ:

```text
ap-south-1a
```

Subnet ID:

```text
subnet-0e58291b6845c7d63
```

---

Private subnet 2:

```text
10.0.12.0/24
```

AZ:

```text
ap-south-1b
```

Subnet ID:

```text
subnet-0d173c81d8264befa
```

---

# 36. Why Public and Private Subnets?

Public subnet:

```text
Resources requiring direct internet connectivity
```

Private subnet:

```text
Internal application/services
```

Our intended architecture:

```text
Public
 |
 +-- Jenkins

Private
 |
 +-- Tomcat
 |
 +-- Tools
      |
      +-- SonarQube
      +-- Nexus
```

This reduces direct internet exposure.

---

# 37. Internet Gateway

Created Internet Gateway:

```text
igw-053d31a9299035889
```

Purpose:

```text
VPC <-> Internet
```

Architecture:

```text
Jenkins
   |
Public Subnet
   |
Route Table
   |
Internet Gateway
   |
Internet
```

---

# 38. NAT Gateway

Created NAT Gateway:

```text
nat-037d6ec04b2ae4996
```

NAT public IP:

```text
43.205.52.17
```

Purpose:

Private resources can access the internet for outbound operations without receiving inbound internet connections directly.

Example:

```text
Private EC2
    |
    v
NAT Gateway
    |
    v
Internet
```

This will be useful for:

```text
apt update
Docker image pull
Tomcat installation
other outbound downloads
```

---

# 39. Why NAT Gateway?

Suppose Tomcat is private.

Tomcat needs to download:

```text
Java
Tomcat
OS packages
```

But we don't want:

```text
Internet
   |
   v
Tomcat
```

Instead:

```text
Tomcat
   |
   v
NAT Gateway
   |
   v
Internet
```

Inbound internet traffic cannot directly initiate connections to the private instance through the NAT Gateway.

---

# 40. Terraform Validation

Before applying infrastructure we used:

```bash
terraform fmt
```

Purpose:

```text
Format Terraform code
```

Then:

```bash
terraform validate
```

Purpose:

```text
Check Terraform configuration syntax and structure
```

Both completed successfully.

---

# 41. Terraform Plan

We generated a plan before applying.

The final plan was:

```text
17 to add
0 to change
0 to destroy
```

This is an important DevOps practice.

We don't immediately run:

```bash
terraform apply
```

Instead:

```text
terraform plan
       |
       v
Review
       |
       v
terraform apply
```

---

# 42. Terraform Apply

We applied the infrastructure successfully.

Actual result:

```text
Apply complete!

Resources:
17 added
0 changed
0 destroyed
```

This is the current major milestone for Repository 1.

---

# 43. Final Terraform Outputs

Terraform produced:

```text
internet_gateway_id = "igw-053d31a9299035889"

nat_eip_public_ip = "43.205.52.17"

nat_gateway_id = "nat-037d6ec04b2ae4996"

private_subnet_ids = [
  "subnet-0e58291b6845c7d63",
  "subnet-0d173c81d8264befa"
]

public_subnet_ids = [
  "subnet-07ad0a97aa7df9be8",
  "subnet-0ae4782bcabba3a67"
]

vpc_cidr = "10.0.0.0/16"

vpc_id = "vpc-04066adbef1f771f5"
```

These outputs are extremely important because Repository 2 will consume them.

---

# 44. Why Terraform Outputs?

Repository 2 needs:

```text
VPC ID
Public subnet IDs
Private subnet IDs
```

Instead of hardcoding:

```hcl
vpc_id = "vpc-04066adbef1f771f5"
```

we expose them as Terraform outputs.

Then Repository 2 can consume:

```text
data.terraform_remote_state.platform.outputs.vpc_id
```

This creates a clean dependency.

---

# 45. Cross-Repository Terraform Architecture

Repository 1:

```text
Terraform
   |
   v
S3 State
   |
   +-- VPC ID
   +-- Public Subnets
   +-- Private Subnets
```

Repository 2:

```text
Terraform Remote State
          |
          v
Repository 1 S3 State
          |
          v
Required Outputs
```

---

# 46. Remote State Configuration for Repository 2

Repository 2 will use:

```hcl
data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    bucket = "shopsphere-terraform-state-652310866649"
    key    = "platform/dev/terraform.tfstate"
    region = "ap-south-1"
  }
}
```

Then:

```hcl
data.terraform_remote_state.platform.outputs.vpc_id
```

will return:

```text
vpc-04066adbef1f771f5
```

Similarly:

```hcl
data.terraform_remote_state.platform.outputs.public_subnet_ids
```

returns the public subnet IDs.

And:

```hcl
data.terraform_remote_state.platform.outputs.private_subnet_ids
```

returns the private subnet IDs.

---

# 47. Important Remote State Concept

`terraform_remote_state` does not read every internal Terraform resource.

It consumes the **root outputs**.

Therefore Repository 1 needs:

```text
outputs.tf
```

Example concept:

```text
VPC Resource
    |
    v
Root Output
    |
    v
S3 State
    |
    v
terraform_remote_state
    |
    v
Repository 2
```

---

# 48. Repository 2 State Separation

Repository 2 should NOT use:

```text
platform/dev/terraform.tfstate
```

Instead it will use a separate key:

```text
application/dev/terraform.tfstate
```

Therefore:

```text
S3 Bucket
|
+-- platform/dev/terraform.tfstate
|
+-- application/dev/terraform.tfstate
```

This is state separation.

---

# 49. Why State Separation?

Repository 1 manages:

```text
VPC
Jenkins
Networking
```

Repository 2 manages:

```text
Tomcat
Tools
Application Infrastructure
```

If both use the same state:

```text
One state
   |
   +-- VPC
   +-- Jenkins
   +-- Tomcat
   +-- Tools
```

the blast radius becomes larger.

With separate states:

```text
Platform State
    |
    +-- VPC
    +-- Jenkins

Application State
    |
    +-- Tomcat
    +-- Tools
```

This is cleaner and safer.

---

# 50. Current Jenkins Tool Versions

Validated on Jenkins EC2:

```text
Java:
21.0.12

JDK 17:
17.0.20

Maven:
3.8.7

Docker:
29.8.1

Docker Compose:
v5.5.1

Trivy:
0.74.0

Git:
2.43.0
```

AWS CLI:

```text
aws-cli/2.36.49
```

---

# 51. Why Two Java Versions?

Jenkins itself is running with Java 21.

The application can use Java 17.

Therefore:

```text
Jenkins Runtime
       |
       +-- Java 21

Application Build
       |
       +-- JDK 17
```

In Jenkins we can configure JDK 17 as the Maven build JDK.

This is common in enterprise environments where the CI server runtime and application runtime are not necessarily identical.

---

# 52. Jenkins Service Validation

We validated:

```bash
sudo systemctl status jenkins --no-pager
```

Jenkins result:

```text
active (running)
```

Jenkins is enabled as a system service.

---

# 53. Jenkins SSH Validation

SSH access was successfully tested:

```bash
ssh -i ~/.ssh/hotfixdevops.pem ubuntu@43.205.215.230
```

Connection succeeded.

This validates:

```text
Internet
   |
   v
SSH
   |
   v
Jenkins EC2
```

---

# 54. Jenkins Web Architecture

Current Jenkins endpoint:

```text
http://43.205.215.230:8080
```

Traffic:

```text
Browser
   |
   v
Jenkins Security Group
   |
TCP 8080
   |
   v
Jenkins EC2
```

Access is restricted to the configured administrator IP.

---

# 55. Jenkins Role Validation

We validated AWS identity from the Jenkins EC2:

```bash
aws sts get-caller-identity
```

Result contained:

```text
arn:aws:sts::652310866649:assumed-role/shopsphere-jenkins-role/...
```

This proves:

```text
Jenkins
   |
   v
EC2 Instance Profile
   |
   v
IAM Role
   |
   v
STS Temporary Credentials
```

---

# 56. Current Project Milestone

At this point:

```text
Repository 1
==============================

Terraform
   |
   +-- VPC                 DONE
   +-- Public Subnets      DONE
   +-- Private Subnets     DONE
   +-- Route Tables        DONE
   +-- IGW                 DONE
   +-- NAT Gateway         DONE
   +-- Jenkins EC2         DONE
   +-- Jenkins SG          DONE
   +-- Jenkins IAM Role    DONE
   +-- Instance Profile   DONE
   +-- S3 Remote State     DONE
   +-- State Migration     DONE
   +-- Terraform Apply     DONE
   +-- Jenkins Validation  DONE
   +-- AWS CLI Validation  DONE
```

---

# 57. Current Architecture

```text
                         AWS
                          |
                    ap-south-1
                          |
                +---------+---------+
                |                   |
                v                   v
             Public              Private
             Network              Network
                |                   |
                |                   |
          Jenkins EC2          Future Services
                |                   |
                |                   +-- Tomcat
                |                   |
                |                   +-- Tools
                |                        |
                |                        +-- SonarQube
                |                        +-- Nexus
                |
                v
          Jenkins IAM Role
                |
                v
          AWS STS Temporary
             Credentials
```

---

# 58. Final Target Architecture

The complete project will eventually look like:

```text
                           GitHub
                              |
             +----------------+----------------+
             |                                 |
             v                                 v
     Repository 1                       Repository 2
     terraform-project                 application-devops
             |                                 |
             |                                 |
             v                                 v
       Terraform                         Java Application
             |                           Jenkinsfile
             |                           Infra Jenkinsfile
             |                           Terraform
             |                                 |
             v                                 |
            AWS                                |
             |                                 |
     +-------+-------+                         |
     |               |                         |
     v               v                         |
    VPC            Jenkins <------------------+
     |               |
     |               +-- Infrastructure Pipeline
     |
     +-- Public Subnets
     |       |
     |       +-- Jenkins
     |
     +-- Private Subnets
             |
             +-- Tomcat
             |
             +-- Tools EC2
                    |
                    +-- SonarQube
                    |
                    +-- Nexus
```

---

# 59. Infrastructure Pipeline

Jenkins will run a separate infrastructure pipeline for Repository 2.

Flow:

```text
Jenkins
   |
   v
Checkout Repository 2
   |
   v
terraform fmt
   |
   v
terraform init
   |
   v
terraform validate
   |
   v
terraform plan
   |
   v
Manual Approval
   |
   v
terraform apply
   |
   v
Terraform Outputs
```

Important:

```text
Infrastructure Pipeline
```

should be used for:

```text
Infrastructure changes
```

not every Java application deployment.

---

# 60. Application CI/CD Pipeline

The application pipeline will eventually look like:

```text
Developer
    |
    v
Git Push
    |
    v
GitHub
    |
    v
Jenkins
    |
    v
Checkout
    |
    v
Maven Build
    |
    v
Unit Tests
    |
    v
SonarQube
    |
    v
Quality Gate
    |
    v
Nexus
    |
    v
Approved WAR
    |
    v
Tomcat
    |
    v
Health Check
    |
    v
Deployment Success
```

---

# 61. Why Nexus?

Nexus will act as the artifact repository.

Instead of Jenkins directly deploying an untracked local build:

```text
Maven
   |
   v
WAR
   |
   v
Tomcat
```

we use:

```text
Maven
   |
   v
WAR
   |
   v
Nexus
   |
   v
Approved Version
   |
   v
Tomcat
```

This gives artifact traceability.

---

# 62. Artifact Versioning

Example:

```text
myapp-1.0.0.war
myapp-1.0.1.war
myapp-1.0.2.war
```

Each version can be tracked.

If version `1.0.2` causes an incident:

```text
Current:
1.0.2

Previous:
1.0.1
```

We can redeploy:

```text
1.0.1
```

This gives us a rollback mechanism.

---

# 63. Why SonarQube?

SonarQube provides static code analysis.

Pipeline:

```text
Developer Code
      |
      v
Maven Build
      |
      v
SonarQube
      |
      v
Quality Gate
      |
      +---- FAIL ---> Stop Pipeline
      |
      +---- PASS ---> Continue
```

This prevents known quality issues from progressing through the pipeline.

---

# 64. Tools EC2

Repository 2 will create a Tools EC2.

It will run:

```text
Docker
 |
 +-- SonarQube
 |
 +-- Nexus
```

Architecture:

```text
Tools EC2
   |
   +-- Docker
        |
        +-- SonarQube :9000
        |
        +-- Nexus :8081
```

Persistent storage will be configured so container recreation does not automatically destroy application data.

---

# 65. Tools Security Group

Expected communication:

```text
Jenkins SG
   |
   +-- TCP 9000 --> SonarQube
   |
   +-- TCP 8081 --> Nexus
```

We do not want:

```text
Internet
   |
   +-- 9000
   +-- 8081
```

open to everyone.

---

# 66. Tomcat Security Group

Expected communication:

```text
Jenkins SG
     |
     | TCP 8080
     v
Tomcat
```

The Tomcat application port should not need to be open to the entire internet.

This demonstrates Security Group-to-Security Group communication.

---

# 67. Enterprise Security Group Model

Final intended model:

```text
                    Jenkins SG
                    /    |    \
                   /     |     \
                  v      v      v
             Tomcat SG Tools SG
                |        |
              8080    9000/8081
```

This is better than:

```text
0.0.0.0/0
```

for internal service communication.

---

# 68. Tomcat Infrastructure

Repository 2 Terraform will create:

```text
Tomcat EC2
```

Terraform will:

```text
Create EC2
   |
   v
Run user_data
   |
   +-- Install Java 17
   +-- Download Tomcat
   +-- Create tomcat user
   +-- Configure /opt/tomcat
   +-- Create systemd service
   +-- Start Tomcat
```

---

# 69. Tomcat Application Deployment

Jenkins will eventually deploy the WAR using Tomcat Manager.

Conceptually:

```text
Nexus
  |
  v
Approved WAR
  |
  v
Jenkins
  |
  v
Tomcat Manager
  |
  v
Tomcat
  |
  v
Application
```

---

# 70. Secrets Management

The following should NOT be hardcoded in Jenkinsfiles:

```text
GitHub credentials
Nexus password
SonarQube token
Tomcat username
Tomcat password
```

Instead:

```text
Jenkins Credentials
```

will be used.

Architecture:

```text
Jenkinsfile
    |
    v
Credentials ID
    |
    v
Jenkins Credentials Store
    |
    v
Secret
```

Secrets should not be printed in pipeline logs.

---

# 71. Terraform Secrets Rule

Avoid putting sensitive passwords directly inside:

```text
.tf
```

files.

Also remember:

```text
Terraform state can contain sensitive values.
```

Therefore state must be protected.

Our state is centralized in S3 and encrypted.

---

# 72. Important Terraform State Rule

Never casually execute:

```bash
rm terraform.tfstate
```

in an active project.

Terraform state is critical project data.

If the backend has been migrated to S3:

```text
S3
 |
 +-- authoritative remote state
```

Do not manually delete local files simply because they still exist.

---

# 73. Terraform Standard Workflow

Our standard workflow:

```text
1. Write Terraform
        |
2. terraform fmt
        |
3. terraform init
        |
4. terraform validate
        |
5. terraform plan
        |
6. Review plan
        |
7. terraform apply
        |
8. Validate AWS resources
```

---

# 74. Terraform Commands

## Initialize

```bash
terraform init
```

Purpose:

```text
Initialize Terraform
Download providers
Configure backend
Initialize modules
```

---

## Format

```bash
terraform fmt
```

Purpose:

```text
Format Terraform files
```

---

## Validate

```bash
terraform validate
```

Purpose:

```text
Validate Terraform configuration
```

---

## Plan

```bash
terraform plan
```

Purpose:

```text
Show expected changes
```

---

## Apply

```bash
terraform apply
```

Purpose:

```text
Create/update infrastructure
```

---

## Show Outputs

```bash
terraform output
```

Purpose:

```text
Display root outputs
```

---

## List State

```bash
terraform state list
```

Purpose:

```text
Show resources tracked by Terraform
```

---

# 75. Terraform Plan vs Apply

Interview answer:

> `terraform plan` is a preview of the changes Terraform intends to make. `terraform apply` actually executes those changes against the target infrastructure.

Example:

```text
terraform plan
     |
     v
17 to add
0 change
0 destroy
```

Then:

```text
terraform apply
     |
     v
AWS infrastructure created
```

---

# 76. Important Lesson — Never Blindly Apply

Before applying:

```text
Review:
+ add
~ change
- destroy
```

Pay special attention to:

```text
destroy
```

because it can remove infrastructure.

---

# 77. Troubleshooting Example — Jenkins Access

If Jenkins becomes inaccessible:

```text
Browser
   |
   X
Jenkins
```

Check:

### Step 1

Verify EC2:

```bash
aws ec2 describe-instances \
  --instance-ids i-0dccda1a62dd6417a \
  --query 'Reservations[0].Instances[0].State.Name'
```

Expected:

```text
running
```

### Step 2

Check Jenkins:

```bash
sudo systemctl status jenkins --no-pager
```

Expected:

```text
active (running)
```

### Step 3

Check port:

```bash
sudo ss -lntp | grep 8080
```

### Step 4

Check Security Group.

### Step 5

Check current public IP.

---

# 78. Troubleshooting Example — AWS CLI

If:

```bash
aws sts get-caller-identity
```

fails from Jenkins:

Check:

```text
1. AWS CLI installed?
2. EC2 IAM profile attached?
3. IAM role trust policy?
4. Instance metadata access?
5. IAM permissions?
```

Important distinction:

```text
NoCredentials / unable to authenticate
```

is different from:

```text
AccessDenied
```

---

# 79. Troubleshooting Example — AccessDenied

Suppose:

```bash
aws ec2 describe-instances
```

returns:

```text
AccessDenied
```

This does NOT necessarily mean authentication failed.

It can mean:

```text
Authentication:
PASS

Authorization:
FAIL
```

The role exists, but the role does not have the required permission.

---

# 80. Current IAM Lesson

Current Jenkins role:

```text
shopsphere-jenkins-role
```

has the correct trust relationship for EC2.

Jenkins successfully assumed the role.

Therefore:

```text
EC2 -> Instance Profile -> IAM Role -> STS
```

is working.

We will add only the permissions required by the infrastructure pipeline later.

---

# 81. Git Workflow for the Project

Repository changes should follow a controlled workflow.

Example:

```text
main
 |
 +-- feature/networking
 |
 +-- feature/jenkins
 |
 +-- feature/iam
 |
 +-- feature/remote-state
```

Then:

```text
feature branch
      |
      v
commit
      |
      v
push
      |
      v
Pull Request
      |
      v
Review
      |
      v
merge
```

---

# 82. Why Git Branching?

We do not want everyone directly modifying:

```text
main
```

Instead:

```text
Developer
   |
   v
Feature Branch
   |
   v
Pull Request
   |
   v
Review
   |
   v
Main
```

This represents a basic enterprise development workflow.

---

# 83. Current Repository 1 Milestone

At this stage, Repository 1 has successfully demonstrated:

```text
Git
Terraform
AWS
VPC
Subnets
Routing
IGW
NAT
EC2
Security Groups
IAM
Instance Profiles
S3 Remote State
Terraform State Migration
Terraform Outputs
Jenkins
AWS CLI
AWS STS
```

---

# 84. What We Have NOT Done Yet

The following belongs to the next phase:

```text
Repository 2
```

Not yet completed:

```text
Tomcat Terraform
Tools Terraform
Tools EC2
SonarQube
Nexus
Docker Compose
Tomcat Manager
Application Jenkinsfile
Infrastructure Jenkinsfile
Repo 2 remote state
Jenkins Terraform permissions
GitHub Jenkins integration
Maven application pipeline
SonarQube Quality Gate
Nexus artifact upload
Tomcat deployment
Health checks
Rollback
Incident simulation
```

These will be built incrementally.

---

# 85. Next Phase Architecture

The next implementation sequence will be:

```text
Repository 2
     |
     v
Create Terraform structure
     |
     v
Configure S3 backend
     |
     v
Read Repository 1 remote state
     |
     v
Create Security Groups
     |
     v
Create Tomcat EC2
     |
     v
Create Tools EC2
     |
     v
Install Docker
     |
     v
Deploy SonarQube + Nexus
     |
     v
Validate services
```

Only after that:

```text
Jenkins Infrastructure Pipeline
```

Then:

```text
Application CI/CD Pipeline
```

---

# 86. Teaching Sequence

For teaching this project, explain in this order.

## Class 1 — Business Requirement

Explain:

```text
Why does the company need DevOps?
```

Then explain:

```text
Application
Infrastructure
CI/CD
```

---

## Class 2 — Repository Architecture

Explain:

```text
Why two repositories?
```

Show:

```text
Repo 1
Platform

Repo 2
Application
```

---

## Class 3 — Terraform Basics

Teach:

```text
provider
resource
variable
module
output
state
backend
```

---

## Class 4 — AWS Networking

Teach:

```text
VPC
CIDR
Subnet
AZ
Route Table
IGW
NAT Gateway
```

---

## Class 5 — Jenkins Infrastructure

Teach:

```text
EC2
user_data
Security Group
Jenkins installation
```

---

## Class 6 — IAM

Teach:

```text
IAM Role
Instance Profile
STS
Temporary Credentials
Authentication
Authorization
Least Privilege
```

---

## Class 7 — Remote State

Teach:

```text
S3 backend
state migration
state locking
outputs
terraform_remote_state
```

---

## Class 8 — Repository 2

Teach:

```text
Tomcat
SonarQube
Nexus
Security Groups
Docker Compose
```

---

## Class 9 — Infrastructure Pipeline

Teach:

```text
Jenkins
Terraform
Plan
Approval
Apply
```

---

## Class 10 — Application CI/CD

Teach:

```text
Git
Maven
Testing
SonarQube
Quality Gate
Nexus
Tomcat
Health Check
Rollback
```

---

# 87. YouTube Recording Structure

For YouTube recording, do NOT try to explain the entire project in one video.

Use a series.

Recommended sequence:

```text
Video 1
Project Introduction + Business Requirement

Video 2
Two Repository Enterprise Architecture

Video 3
Terraform Project Structure

Video 4
AWS VPC and Networking

Video 5
Terraform Modules

Video 6
Jenkins EC2 using Terraform

Video 7
Jenkins Security Group

Video 8
Jenkins IAM Role + Instance Profile

Video 9
AWS STS Authentication

Video 10
Terraform S3 Remote Backend

Video 11
Terraform State Migration

Video 12
Terraform Remote State Between Repositories

Video 13
Tomcat Infrastructure

Video 14
SonarQube + Nexus Infrastructure

Video 15
Infrastructure Jenkins Pipeline

Video 16
Java Application CI Pipeline

Video 17
SonarQube Quality Gate

Video 18
Nexus Artifact Management

Video 19
Tomcat Deployment

Video 20
Rollback + Incident Simulation

Video 21
Enterprise DevOps Interview Questions
```

---

# 88. YouTube Teaching Rule

For every topic, follow this structure:

```text
WHAT
 |
WHY
 |
WHERE
 |
HOW
 |
REAL-TIME EXAMPLE
 |
ARCHITECTURE
 |
COMMAND
 |
OUTPUT
 |
TROUBLESHOOTING
 |
INTERVIEW QUESTION
```

Example:

```text
IAM Role

WHAT?
Identity for AWS access

WHY?
Avoid static credentials

WHERE?
Jenkins EC2

HOW?
Instance Profile -> IAM Role

REAL-TIME:
Jenkins Terraform

VALIDATION:
aws sts get-caller-identity

INTERVIEW:
How does Jenkins authenticate with AWS?
```

---

# 89. Interview Explanation — Overall Architecture

A strong interview explanation:

> "I designed the project using two repositories. The first repository manages the core AWS platform infrastructure such as the VPC, networking, and Jenkins. The second repository manages the application and application-specific infrastructure such as Tomcat and the SonarQube/Nexus tools. The second repository consumes VPC and subnet information from the first repository through Terraform remote state. Jenkins runs separate infrastructure and application pipelines, so infrastructure changes are separated from normal application deployments."

---

# 90. Interview Question — Why Two Repositories?

Answer:

> "I separated platform infrastructure from application infrastructure to reduce coupling and blast radius. The platform repository owns shared components such as networking and Jenkins, while the application repository owns application-specific resources. The application repository consumes platform outputs using Terraform remote state instead of recreating the VPC."

---

# 91. Interview Question — How Does Repository 2 Know the VPC?

Answer:

> "Repository 1 publishes the VPC and subnet information through Terraform root outputs. Those outputs are stored in the S3-backed Terraform state. Repository 2 uses the `terraform_remote_state` data source to consume those outputs."

---

# 92. Interview Question — Why S3 Backend?

Answer:

> "I use an S3 backend to centralize Terraform state so it is not tied to one developer's workstation. It also provides centralized state management, encryption, versioning capabilities, and state locking through the configured S3 lockfile mechanism."

---

# 93. Interview Question — How Does Jenkins Authenticate to AWS?

Answer:

> "Jenkins runs on an EC2 instance with an IAM instance profile attached. The instance profile provides the Jenkins IAM role, and AWS STS provides temporary credentials. I avoid storing static AWS access keys on the Jenkins server."

---

# 94. Interview Question — Authentication vs Authorization?

Answer:

> "Authentication verifies who the caller is, while authorization determines what the caller is allowed to do. In this project, `aws sts get-caller-identity` confirmed that Jenkins is assuming the `shopsphere-jenkins-role`. The role's actual AWS permissions are handled separately through IAM policies."

---

# 95. Interview Question — Why Not AdministratorAccess?

Answer:

> "Jenkins is a high-value automation system, so giving it AdministratorAccess would unnecessarily increase the blast radius. I prefer least privilege and grant only the AWS actions required by the Terraform infrastructure pipeline."

---

# 96. Interview Question — Why NAT Gateway?

Answer:

> "Private instances may need outbound internet access for operations such as package installation or downloading dependencies, but they should not be directly reachable from the internet. A NAT Gateway provides outbound connectivity for private subnets while keeping those instances private."

---

# 97. Interview Question — What Happens If Jenkins EC2 Is Destroyed?

Because Jenkins is currently infrastructure managed by Terraform:

```text
Terraform
    |
    v
Jenkins EC2
```

If it is destroyed:

```text
Terraform apply
    |
    v
New Jenkins EC2
```

But Jenkins application configuration/data must be considered separately.

This is why enterprise Jenkins deployments should consider:

```text
backup
persistent storage
configuration as code
Jenkins Configuration as Code
```

for production environments.

For this training project, Jenkins infrastructure is intentionally provisioned through Terraform so the infrastructure lifecycle can be demonstrated.

---

# 98. Current Project Evidence

## AWS Account

```text
652310866649
```

## Region

```text
ap-south-1
```

## VPC

```text
vpc-04066adbef1f771f5
```

## VPC CIDR

```text
10.0.0.0/16
```

## Jenkins Instance

```text
i-0dccda1a62dd6417a
```

## Jenkins Public IP

```text
43.205.215.230
```

## Jenkins Private IP

```text
10.0.1.137
```

## Jenkins Security Group

```text
sg-0dfadc1b44ab161ec
```

## Jenkins IAM Role

```text
shopsphere-jenkins-role
```

## Jenkins Instance Profile

```text
shopsphere-jenkins-profile
```

## S3 State Bucket

```text
shopsphere-terraform-state-652310866649
```

## Platform State Key

```text
platform/dev/terraform.tfstate
```

---

# 99. Final Current-State Diagram

```text
                           GitHub
                              |
                              |
                +-------------+-------------+
                |                           |
                v                           v
       terraform-project             Repository 2
       Platform Repo                 Application Repo
                |                           |
                |                           |
                v                           |
            Terraform                        |
                |                           |
                v                           |
             AWS VPC                         |
          10.0.0.0/16                        |
                |                           |
       +--------+---------+                  |
       |                  |                  |
       v                  v                  |
    Public             Private               |
    Subnets            Subnets               |
       |                  |                  |
       v                  |                  |
   Jenkins               |                  |
   EC2                   |                  |
       |                  |                  |
       v                  |                  |
 IAM Instance             |                  |
 Profile                  |                  |
       |                  |                  |
       v                  |                  |
 IAM Role                 |                  |
       |                  |                  |
       v                  |                  |
 AWS STS                  |                  |
                          |                  |
                          +------------------+
                              Remote State
```

---

# 100. Current Completion Status

```text
========================================
REPOSITORY 1
PLATFORM / CORE INFRASTRUCTURE
========================================

[✓] Terraform project
[✓] AWS provider
[✓] VPC
[✓] Public subnets
[✓] Private subnets
[✓] Route tables
[✓] Internet Gateway
[✓] NAT Gateway
[✓] NAT EIP
[✓] Jenkins EC2
[✓] Jenkins Security Group
[✓] Jenkins user_data
[✓] Jenkins IAM Role
[✓] Jenkins Instance Profile
[✓] S3 Terraform backend
[✓] State migration
[✓] State locking configuration
[✓] Terraform outputs
[✓] terraform fmt
[✓] terraform validate
[✓] terraform plan
[✓] terraform apply
[✓] SSH validation
[✓] Jenkins service validation
[✓] AWS CLI validation
[✓] AWS STS validation
[✓] IAM role authentication validation
```

---

# 101. Next Milestone

The next milestone is:

```text
REPOSITORY 2
APPLICATION + APPLICATION INFRASTRUCTURE
```

First we will build:

```text
Repo 2
   |
   +-- Terraform backend
   |
   +-- terraform_remote_state
   |
   +-- Tomcat Security Group
   |
   +-- Tools Security Group
   |
   +-- Tomcat EC2
   |
   +-- Tools EC2
   |
   +-- Docker
   |
   +-- SonarQube
   |
   +-- Nexus
```

Then:

```text
Jenkins Infrastructure Pipeline
```

Then:

```text
Java Application CI/CD
```

Then:

```text
Deployment
Testing
Health Check
Rollback
Incident Simulation
Interview Preparation
```

---

# 102. Golden Rule for This Project

Always remember:

```text
Terraform
=
Build and manage infrastructure
```

and:

```text
Jenkins Application Pipeline
=
Build, test, scan, package and deploy application
```

Therefore:

```text
                DEVOPS PROJECT
                     |
          +----------+----------+
          |                     |
          v                     v
     Infrastructure          Application
        Terraform              Jenkins
          |                      |
          v                      v
     AWS Resources         Build/Test/Scan
                                 |
                                 v
                              Nexus
                                 |
                                 v
                              Tomcat
```

This separation is one of the most important concepts in the project.

---

# 103. Current Milestone Summary

We have now completed the **Platform Foundation**.

The foundation consists of:

```text
AWS
 |
 +-- VPC
 |    |
 |    +-- Public Subnets
 |    +-- Private Subnets
 |    +-- IGW
 |    +-- NAT Gateway
 |
 +-- Jenkins
      |
      +-- EC2
      +-- Security Group
      +-- IAM Role
      +-- Instance Profile
      +-- AWS CLI
      +-- Terraform-ready environment
```

The platform is now ready for the next layer.

```text
             PLATFORM FOUNDATION
                     |
                     v
              Repository 2
                     |
          +----------+----------+
          |                     |
          v                     v
     Infrastructure          Application
       Tomcat/Tools            CI/CD
```

---

# 104. Recording Checkpoint

### YouTube Recording Checkpoint — Completed

Before moving to Repository 2, record the following:

```text
[✓] Project business requirement
[✓] Why two repositories
[✓] Repository 1 structure
[✓] Terraform architecture
[✓] VPC architecture
[✓] Public/private subnet architecture
[✓] IGW
[✓] NAT Gateway
[✓] Jenkins EC2
[✓] Jenkins bootstrap
[✓] Jenkins Security Group
[✓] IAM Role
[✓] Instance Profile
[✓] Authentication vs Authorization
[✓] AWS STS validation
[✓] S3 remote state
[✓] State migration
[✓] Terraform outputs
[✓] Terraform plan
[✓] Terraform apply
[✓] Actual AWS resource validation
[✓] Current architecture
```

After recording this checkpoint, we can continue from:

```text
NEXT:
Repository 2
Remote State Consumer
```

---

# 105. Project Status

```text
========================================
SHOPSPHERE ENTERPRISE DEVOPS PROJECT
========================================

Phase 1
Project Design                 COMPLETE

Phase 2
Repository 1                   COMPLETE

Phase 3
AWS Networking                 COMPLETE

Phase 4
Jenkins Infrastructure         COMPLETE

Phase 5
Jenkins IAM                    COMPLETE

Phase 6
Terraform Remote State         COMPLETE

Phase 7
Repository 2                   NEXT

Phase 8
Tomcat Infrastructure          PENDING

Phase 9
SonarQube + Nexus              PENDING

Phase 10
Infrastructure Pipeline        PENDING

Phase 11
Application CI/CD              PENDING

Phase 12
Deployment                     PENDING

Phase 13
Rollback                       PENDING

Phase 14
Incident Simulation            PENDING

Phase 15
Enterprise Interview           PENDING
```

---

# 106. One-Line Interview Summary

> **"This project demonstrates an enterprise-style two-repository DevOps architecture where Terraform manages the AWS platform infrastructure and Jenkins manages application delivery, with secure IAM role-based AWS authentication, S3-backed Terraform state, cross-repository remote-state consumption, automated infrastructure provisioning, code quality scanning, artifact management, and Tomcat deployment."**

---

# 107. End of Current Milestone

```text
================================================
             PLATFORM FOUNDATION
                  COMPLETED
================================================

Terraform
     |
     v
AWS VPC
     |
     +-- Public Network
     |      |
     |      +-- Jenkins
     |
     +-- Private Network
            |
            +-- Future Tomcat
            |
            +-- Future Tools

Jenkins
     |
     v
IAM Instance Profile
     |
     v
IAM Role
     |
     v
AWS STS

Terraform State
     |
     v
S3
     |
     +-- platform/dev/terraform.tfstate
```

**Next implementation starts with Repository 2.**

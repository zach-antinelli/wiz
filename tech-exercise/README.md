# Tech Exercise

[Instructions](/tech-exercise/wiz-provided/Wiz_Field_Tech_Exercise_v3.0_Instructions.pdf)

Thank you for the opportunity! I've laid out my architecture and overview of the solutions based on the provided instructions.

## 📖 Table of Contents

- **[Technology Stack](#technology-stack)**
  Overview of the tools and technologies used.

- **[Misconfigurations](#misconfigurations)**
  Identified issues and their remediations.

- **[Security Tools](#security-tools)**
  - 🔍 **[Detective](#detective)**: Tools for monitoring and detection.
  - 🛡️ **[Preventative](#preventative)**: Tools for proactive security.
  - 🚨 **[Responsive](#responsive)**: Tools for incident response.

## Technology stack

- Terraform infrastructure deployment
- Web Application
  - EC2 instance running DB
    - Overly permissive IAM role
    - DB allows local authentication
    - DB Backup automation to S3
- K8S cluster
  - Container with webapp running with cluster admin SA
- S3 Bucket for object storage
  - Database backups
  - Scripts, content
- Code stored in GitHub
- GitHub actions pipelines
  - Automate Terraform deployment
  - Build and push image to ECR

## Misconfigurations

- IMDSv1 for EC2 instance
  - [AWS Docs](https://aws.amazon.com/blogs/security/get-the-full-benefits-of-imdsv2-and-disable-imdsv1-across-your-aws-infrastructure/)
  - Remediated with Security Hub
- ? for DB
- ? for K8S

## Security Tools

### Detective

[AWS Detective Controls](https://docs.aws.amazon.com/prescriptive-guidance/latest/aws-security-controls/detective-controls.html)

[AWS Inspector](https://docs.aws.amazon.com/inspector)

[Prowler](https://github.com/prowler-cloud/prowler)

| Tool         | Use                                        |
| ------------ | ------------------------------------------ |
| GuardDuty    | Threat Detection                           |
| Security Hub | Security and compliance findings           |
| Inspector    | Vulnerability assessment and exposure      |
| Prowler      | Open Source command-line security findings |

### Preventative

[AWS Preventative Controls](https://docs.aws.amazon.com/prescriptive-guidance/latest/aws-security-controls/preventative-controls.html)

| Tool                       | Use                               |
| -------------------------- | --------------------------------- |
| IAM Policies               | Risk mitigation                   |
| IAM Permissions boundaries | Reduce overly permissive policies |

### Responsive

[AWS Responsive Controls](https://docs.aws.amazon.com/prescriptive-guidance/latest/aws-security-controls/responsive-controls.html)

- GuardDuty: Threat Detection and Response
  - Simulate a detection and response action
- Security Hub: Security finding remediation

**NOTE**: Make a Python script to query results, store in S3 and pull down locally.

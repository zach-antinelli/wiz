# Tech Exercise

[Instructions](_instructions/Wiz_Field_Tech_Exercise_v3.0_Instructions.pdf)

Thank you for the opportunity! I've laid out my architecture and overview of the solutions based on the provided instructions.

## 📖 Table of Contents

- **[Technology Stack](#technology-stack)**
  Overview of the tools and technologies used.
  - **[Architecture Diagram](#infrastructure-diagram)**

- **[Misconfigurations](#misconfigurations)**
  Identified issues and their remediations.

- **[Security Tools](#security-tools)**
  - 🔍 **[Detective](#detective)**: Tools for monitoring and detection.
  - 🛡️ **[Preventative](#preventative)**: Tools for proactive security.
  - 🚨 **[Responsive](#responsive)**: Tools for incident response.

## Technology stack

- Terraform infrastructure deployment
- Web application
  - Custom app built with Python: [gensen](web-app/gensen)
  - Custom helm chart to deploy app: [helm](web-app/helm)
  - Hosted publicly at [wiz-tech-exercise.zachantinelli.me](https://wiz-tech-exercise.zachantinelli.me)
- K8S cluster
  - Pod with web app running cluster admin SA
  - Load balancer controller manages ingress and ALB access to webapp
- EC2 instance running DB
  - Overly permissive IAM role
  - DB allows local authentication
  - DB Backup automation to S3
- S3 Bucket for object storage
  - Database backups
- Code stored in GitHub
- GitHub actions pipelines
  - Automate Terraform deployment
  - Build and push image to ECR

### Infrastructure diagram

<img src="https://zach-antinelli.github.io/wiz/infra.svg" alt="Architecture" width="75%" />

## Misconfigurations

- IMDSv1 for Database EC2 instance
  - Detected by AWS Config, remediated with SSM automation document.
- EKS cluster endpoint publicly available
  - Detected by AWS Config, remediated with SSM automation document.

## Security Tools

### Detective

[AWS Detective Controls](https://docs.aws.amazon.com/prescriptive-guidance/latest/aws-security-controls/detective-controls.html)

| Tool                                                    | Use                                          |
| ------------------------------------------------------- | -------------------------------------------- |
| [Config](https://docs.aws.amazon.com/config)            | Detect misconfigurtions                      |
| [GuardDuty](https://docs.aws.amazon.com/guardduty)      | Threat detection                             |
| [Security Hub](https://docs.aws.amazon.com/securityhub) | Centralized security and compliance findings |
| [Inspector](https://docs.aws.amazon.com/inspector)      | Vulnerability assessment and exposure        |
| [Prowler](https://github.com/prowler-cloud/prowler)     | Open Source command-line security findings   |

### Preventative

[AWS Preventative Controls](https://docs.aws.amazon.com/prescriptive-guidance/latest/aws-security-controls/preventative-controls.html)

| Tool            | Use             |
| --------------- | --------------- |
| IAM Policies    | Risk mitigation |
| Security groups | Risk mitigation |

### Responsive

[AWS Responsive Controls](https://docs.aws.amazon.com/prescriptive-guidance/latest/aws-security-controls/responsive-controls.html)

| Tool             | Use                           |
| ---------------- | ----------------------------- |
| AWS Config + SSM | Remediate misconfigurations   |
| GuardDuty        | Threat Detection and Response |

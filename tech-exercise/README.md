# Tech Exercise

[Instructions](_instructions/Wiz_Field_Tech_Exercise_v3.0_Instructions.pdf)

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

## Misconfigurations

- IMDSv1 for EC2 instance
  - Remediated with Lambda function executed through AWS Config
- EKS cluster endpoint available on `0.0.0.0/0`
  - Remediated with Lambda function executed through AWS Config

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

| Tool            | Use             |
| --------------- | --------------- |
| IAM Policies    | Risk mitigation |
| Security groups | Risk mitigation |
| GuardDuty       | Risk mitigation |

### Responsive

[AWS Responsive Controls](https://docs.aws.amazon.com/prescriptive-guidance/latest/aws-security-controls/responsive-controls.html)

- GuardDuty: Threat Detection and Response
  - Simulate a detection and response action
- Security Hub: Security finding remediation

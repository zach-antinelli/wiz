# wiz interview

Hey Patrick 👋, I am excited to be interviewing with you.

Here are some resources for our interview:

| Link     | Description |
|----------|----------|
| [GH Pages Site](https://zachantinelli.me) | Github pages site, link to resume in upper right |
| [Interview Demo](https://wiz.zachantinelli.me)   | Demo of whoami app hosted on EKS |
| [whoami.yaml](/whoami.yaml) | k8s manifest for basic app demo |
| [tf-eks](https://github.com/zachantinelli/tf-eks) | Terraform for EKS cluster used by demo |

## Demo app

I am hosting a basic web app on AWS EKS using a container image `traefik/whoami` to display OS and HTTP request details.

- Route53 for DNS.
- ALB for application layer traffic and SSL termination.
- EKS hosting application pod, ingress, service and deployment.

### Diagram
![app](/app.png)
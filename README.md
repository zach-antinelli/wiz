# wiz interview

Hey Patrick 👋, I am excited to be interviewing with you!

Here are some resources I prepared for today:

| Link     | Description |
|----------|----------|
| [GH Pages Site](https://zachantinelli.me) | Github pages site, link to resume in upper right |
| [Demo](https://wiz.zachantinelli.me)   | Demo of whoami app hosted on EKS |
| [whoami.yaml](/whoami.yaml) | k8s manifest for basic app demo |
| [tf-eks](https://github.com/zachantinelli/tf-eks) | Terraform for EKS cluster used by demo |

## Demo app

I am hosting a basic web app on AWS EKS using a container image `traefik/whoami` to display OS and HTTP request details.

```
Hostname: whoami-66c94d8bc8-kzhq4
IP: 127.0.0.1
IP: ::1
IP: 10.0.1.11
IP: fe80::385a:c0ff:fe43:234d
RemoteAddr: 10.0.103.75:63216
GET / HTTP/1.1
Host: wiz.zachantinelli.me
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
Accept-Encoding: gzip, deflate, br, zstd
Accept-Language: en-US,en;q=0.9
Cache-Control: max-age=0
Dnt: 1
Priority: u=0, i
Sec-Ch-Ua: "Google Chrome";v="135", "Not-A.Brand";v="8", "Chromium";v="135"
Sec-Ch-Ua-Mobile: ?0
Sec-Ch-Ua-Platform: "macOS"
Sec-Fetch-Dest: document
Sec-Fetch-Mode: navigate
Sec-Fetch-Site: none
Sec-Fetch-User: ?1
Upgrade-Insecure-Requests: 1
X-Amzn-Trace-Id: Root=1-67fce183-73ef89146b866b3c13315897
X-Forwarded-For: 71.238.46.140
X-Forwarded-Port: 443
X-Forwarded-Proto: https

```

### Components

- Route53 for DNS.
- ALB for application layer traffic and SSL termination.
- EKS hosting application pod, ingress, service and deployment.
- ECR for container image storage.

### Diagram
![app](/app.png)
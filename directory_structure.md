# Directory Structure and Contents for terraform

- README.md (6371 bytes)
  ```
  # Terraform Project Documentation

## Project Overview

This Terraform project sets up a secure and scalable infrastructure on AWS to serve a static website using S3, CloudFront, ACM (for SSL certificates), and Route53 for DNS management. The infrastructure includes:

- An S3 bucket for hosting static content.

- A CloudFront distribution for content delivery.

- An ACM certificate for HTTPS support.

- Route53 DNS records for domain mapping.

- Secure access configurations using Origin Access Identity (OAI).

## Prerequisites

Before you begin, ensure you have the following:

- **AWS Account** : An active AWS account with appropriate permissions.

- **Terraform Installed** : Terraform v1.5.7 or compatible installed on your machine.

- **AWS CLI Configured** : AWS CLI installed and configured with your AWS credentials.

- **Domain Name** : A registered domain name, managed in AWS Route53.

## Directory Structure

```css
├── acm.tf
├── cloudfront.tf
├── main.tf
├── output.tf
├── provider.tf
├── route53.tf
├── terraform.tfstate
├── terraform.tfvars
├── variable.tf
├── modules/
│   ├── cloudfront_module/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── s3_module/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── route53_module/
│       ├── main.tf
│       ├── variables.tf
│       └── README.md
└── templates/
    └── upload.html
```

## Modules Explanation

CloudFront Module (`modules/cloudfront_module`)

- **Purpose** : Creates a CloudFront distribution and an Origin Access Identity (OAI) to securely serve content from the S3 bucket over HTTPS.

- **Key Resources** :
  - `aws_cloudfront_distribution`

  - `aws_cloudfront_origin_access_identity`
S3 Module (`modules/s3_module`)
- **Purpose** : Creates an S3 bucket for static website hosting, configures bucket policies, and uploads the initial `upload.html` file.

- **Key Resources** :
  - `aws_s3_bucket`

  - `aws_s3_bucket_policy`

  - `aws_s3_bucket_public_access_block`

  - `aws_s3_object`
Route53 Module (`modules/route53_module`)
- **Purpose** : Manages Route53 DNS records to route traffic to the CloudFront distribution.

- **Key Resources** :
  - `aws_route53_record`

  - Data source `aws_route53_zone`

## Variables and Configuration

Required Variables (`variable.tf`)

- `s3_bucket_name`: Name of the S3 bucket.

- `acm_certificate_domain`: Domain name for the ACM certificate (e.g., `www.example.com`).

- `subdomain_name`: Subdomain for the website (e.g., `www`).

- `domain_name`: Root domain name (e.g., `example.com`).

- `aws_region`: AWS region for the resources (e.g., `us-east-1`).

- `environment`: Deployment environment (`dev`, `staging`, `prod`).

### Variable Definitions

Define your variables in the `terraform.tfvars` file or pass them via command-line or environment variables.Example `terraform.tfvars`:**

```hcl
s3_bucket_name         = "your-bucket-name"
acm_certificate_domain = "your.domain.com"
subdomain_name         = "www"
domain_name            = "your.domain.com"
aws_region             = "us-east-1"
environment            = "prod"
```

## Usage Instructions

### Step 1: Clone the Repository

```bash
git clone 
cd repo 
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Validate the Configuration

```bash
terraform validate
```

### Step 4: Review the Execution Plan

```bash
terraform plan
```

### Step 5: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### Step 6: Access Your Website

After the deployment is complete, you can access your website using the domain name specified.

## Deployment Steps Explained

1. **ACM Certificate Creation (`acm.tf`)** :

- Creates an ACM certificate in `us-east-1` (required for CloudFront).

- Validates the certificate using DNS validation via Route53.

2. **S3 Bucket Setup (`main.tf` invoking `s3_module`)** :

- Creates an S3 bucket for static website hosting.

- Configures bucket policies to allow access from CloudFront via OAI.

- Uploads the `upload.html` file to the bucket.

3. **CloudFront Distribution Setup (`main.tf` invoking `cloudfront_module`)** :

- Creates a CloudFront distribution pointing to the S3 bucket.

- Sets up an OAI for secure access to the S3 bucket.

- Configures SSL using the ACM certificate.

4. **Route53 DNS Records (`route53.tf` invoking `route53_module`)** :

- Creates an A record in Route53 pointing your domain to the CloudFront distribution.

## Troubleshooting

### Access Denied Errors

If you encounter `Access Denied` errors when accessing your website, ensure:

- The S3 bucket policy correctly references the OAI's IAM ARN.

- The CloudFront distribution is using the correct OAI.

- The S3 bucket does not allow public access and relies solely on CloudFront for content delivery.

### Common Commands

- **Refresh State** : `terraform refresh`

- **Destroy Resources** : `terraform destroy`

- **View State** : `terraform state list`

### Potential Issues and Solutions

- **Certificate Validation Failed** : Ensure your domain is correctly set up in Route53 and that the DNS validation record has been created.

- **OAI Conflicts** : Avoid defining multiple OAIs across modules. Manage the OAI within the `cloudfront_module` to prevent conflicts.

## Best Practices

- **Module Encapsulation** : Keep modules self-contained to promote reusability and maintainability.

- **State Management** : Use remote state backends like S3 with state locking enabled to prevent concurrent modifications.

- **Version Control** : Track your Terraform configurations in a version control system like Git.

- **Variable Management** : Use Terraform variables and `tfvars` files to manage environment-specific configurations.

- **Resource Naming** : Use consistent naming conventions for resources to make management easier.

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)

- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

- [Terraform Best Practices](https://www.terraform-best-practices.com)

  ```
- acm.tf (992 bytes)
  ```
  
# Create the ACM certificate

resource "aws_acm_certificate" "cert" {
  domain_name       = var.acm_certificate_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  provider = aws.us_east_1
}

# Validate the ACM certificate

resource "aws_acm_certificate_validation" "cert_validation" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# DNS validation records for ACM certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

  ```
- cloudfront.tf (18 bytes)
  ```
  # Outputs for OAI

  ```
- directory_structure.md (0 bytes)
  ```
  
  ```
- main.tf (714 bytes)
  ```
  # Invoke the CloudFront module
module "cloudfront" {
  source              = "./modules/cloudfront_module"
  s3_bucket_name      = var.s3_bucket_name
  acm_certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
  subdomain_name      = var.subdomain_name
  domain_name         = var.domain_name
  aws_region          = var.aws_region
  environment         = var.environment
}


# Adjust the S3 module invocation
module "s3" {
  source = "./modules/s3_module"

  s3_bucket_name = var.s3_bucket_name
  environment    = var.environment
  aws_region     = var.aws_region
  # Pass the OAI IAM ARN from the CloudFront module
  cloudfront_oai_iam_arn = module.cloudfront.cloudfront_oai_iam_arn
}

  ```
- **modules/**
  - **cloudfront_module/**
    - README.md (1179 bytes)
      ```
      # CloudFront Module

This module creates a CloudFront distribution to serve content from an S3 bucket securely using HTTPS.

## Inputs

- **s3_bucket_name** (string): Name of the S3 bucket serving as the origin.
- **acm_certificate_arn** (string): ARN of the ACM certificate for HTTPS support.
- **subdomain_name** (string): Subdomain for the website (e.g., "www").
- **domain_name** (string): Root domain name (e.g., "example.com").
- **aws_region** (string): AWS region where the resources are located.
- **cloudfront_oai_id** (string): ID of the CloudFront Origin Access Identity.
- **environment** (string): Environment name (e.g., "dev", "staging", "prod").

## Outputs

- **cloudfront_domain_name**: The domain name of the CloudFront distribution (e.g., "d123456abcdef.cloudfront.net").

## Usage

```hcl
module "cloudfront" {
  source = "./modules/cloudfront_module"

  s3_bucket_name      = var.s3_bucket_name
  acm_certificate_arn = var.acm_certificate_arn
  subdomain_name      = var.subdomain_name
  domain_name         = var.domain_name
  aws_region          = var.aws_region
  environment         = var.environment
  cloudfront_oai_id   = var.cloudfront_oai_id
}
```
      ```
    - main.tf (1266 bytes)
      ```
      resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for CloudFront access to ${var.s3_bucket_name}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  default_root_object = "upload.html"

  aliases = ["${var.subdomain_name}.${var.domain_name}"]

  origin {
    domain_name = "${var.s3_bucket_name}.s3.${var.aws_region}.amazonaws.com"
    origin_id   = "s3_origin"

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.oai.id}"
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3_origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Viewer certificate configuration (ACM Certificate for HTTPS)
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = var.environment
  }

}

      ```
    - outputs.tf (285 bytes)
      ```
      output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "cloudfront_oai_iam_arn" {
  value = aws_cloudfront_origin_access_identity.oai.iam_arn
}

output "cloudfront_oai_id" {
  value = aws_cloudfront_origin_access_identity.oai.id
}
      ```
    - variables.tf (627 bytes)
      ```
      variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
}

variable "subdomain_name" {
  description = "Subdomain for the website"
  type        = string
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the S3 bucket is located"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

      ```
  - **route53_module/**
    - README.md (994 bytes)
      ```
      # Route53 Module

This module creates Route53 DNS records to route traffic to your CloudFront distribution.

## Inputs

- **domain_name** (string): Root domain name (e.g., "example.com").
- **subdomain_name** (string): Subdomain for the website (e.g., "www").
- **cloudfront_distribution_domain_name** (string): Domain name of the CloudFront distribution (e.g., "d123456abcdef.cloudfront.net").
- **aws_region** (string): AWS region where the resources are located.
- **environment** (string): Deployment environment (e.g., "dev", "staging", "prod").

## Outputs

- *(No outputs specified in the module.)*

## Usage

```hcl
module "route53" {
  source = "./modules/route53_module"

  domain_name                         = var.domain_name
  subdomain_name                      = var.subdomain_name
  cloudfront_distribution_domain_name = var.cloudfront_distribution_domain_name
  aws_region                          = var.aws_region
  environment                         = var.environment
}
```

      ```
    - main.tf (505 bytes)
      ```
      data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
}

# Create an A record alias pointing to the CloudFront distribution
resource "aws_route53_record" "cloudfront_alias" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.subdomain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_distribution_domain_name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront Hosted Zone ID
    evaluate_target_health = false
  }
}

      ```
    - output.tf (0 bytes)
      ```
      
      ```
    - variables.tf (537 bytes)
      ```
      variable "domain_name" {
  description = "Root domain name"
  type        = string
}

variable "subdomain_name" {
  description = "Subdomain name"
  type        = string
}

variable "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

      ```
  - **s3_module/**
    - README.md (740 bytes)
      ```
      # S3 Module

This module creates an S3 bucket for static website hosting.

## Inputs

- `s3_bucket_name` (string): Name of the S3 bucket.
- `aws_region` (string): AWS region where the bucket will be created.
- `environment` (string): Deployment environment (dev, staging, prod).
- `cloudfront_oai_iam_arn` (string): IAM ARN of the CloudFront Origin Access Identity.

## Outputs

- `bucket_name`: The name of the created S3 bucket.
- `bucket_region`: The AWS region of the S3 bucket.

## Usage

```hcl
module "s3" {
  source = "./modules/s3_module"

  s3_bucket_name         = var.s3_bucket_name
  aws_region             = var.aws_region
  environment            = var.environment
  cloudfront_oai_iam_arn = var.cloudfront_oai_iam_arn
}
```

      ```
    - main.tf (1168 bytes)
      ```
      resource "aws_s3_bucket" "bucket_website" {
  bucket = var.s3_bucket_name
  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket_ownership_controls" {
  bucket = aws_s3_bucket.bucket_website.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
  bucket = aws_s3_bucket.bucket_website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "upload_html" {
  bucket = aws_s3_bucket.bucket_website.id
  key    = "upload.html"
  source = "./../templates/upload.html"
  acl    = "private"
  content_type = "text/html"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket_website.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket_website.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [var.cloudfront_oai_iam_arn]
    }
  }
}
      ```
    - outputs.tf (222 bytes)
      ```
      output "bucket_name" {
  value       = aws_s3_bucket.bucket_website.bucket
  description = "Name of the S3 bucket"
}

output "bucket_region" {
  value       = var.aws_region
  description = "AWS region of the S3 bucket"
}

      ```
    - variables.tf (661 bytes)
      ```
      variable "s3_bucket_name" {
  description = "Name of the S3 bucket for static website hosting"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the S3 bucket is located"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of dev, staging, or prod."
  }
}

variable "cloudfront_oai_iam_arn" {
  description = "IAM ARN of the CloudFront Origin Access Identity"
  type        = string
}

      ```
- output.tf (148 bytes)
  ```
  output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "cloudfront_domain_name" {
  value = module.cloudfront.cloudfront_domain_name
}

  ```
- provider.tf (303 bytes)
  ```
  terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Provider for us-east-1 (required for ACM certificate used by CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

  ```
- route53.tf (522 bytes)
  ```
  # Invoke the Route53 module
module "route53" {
  source = "./modules/route53_module"

  domain_name                         = var.domain_name
  subdomain_name                      = var.subdomain_name
  environment                         = var.environment
  cloudfront_distribution_domain_name = module.cloudfront.cloudfront_domain_name
  aws_region                          = var.aws_region
}

# Data source for Route 53 zone
data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
}

  ```
- terraform.tfstate (23697 bytes)
  ```
  {
  "version": 4,
  "terraform_version": "1.5.7",
  "serial": 169,
  "lineage": "c9e42b6c-96f2-7ab4-aab6-c8d148bbcc37",
  "outputs": {
    "cloudfront_domain_name": {
      "value": "d3hjh3sl3eu49l.cloudfront.net",
      "type": "string"
    },
    "s3_bucket_name": {
      "value": "csv.yuandrk.net",
      "type": "string"
    }
  },
  "resources": [
    {
      "mode": "data",
      "type": "aws_route53_zone",
      "name": "primary",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "arn": "arn:aws:route53:::hostedzone/Z00590051L9DQ0G85AMA6",
            "caller_reference": "RISWorkflow-RD:42f7d6e0-16fe-410b-a1e1-e23c085fc69c",
            "comment": "HostedZone created by Route53 Registrar",
            "id": "Z00590051L9DQ0G85AMA6",
            "linked_service_description": null,
            "linked_service_principal": null,
            "name": "yuandrk.net",
            "name_servers": [
              "ns-58.awsdns-07.com",
              "ns-1895.awsdns-44.co.uk",
              "ns-1352.awsdns-41.org",
              "ns-530.awsdns-02.net"
            ],
            "primary_name_server": "ns-58.awsdns-07.com",
            "private_zone": false,
            "resource_record_set_count": 4,
            "tags": {},
            "vpc_id": null,
            "zone_id": "Z00590051L9DQ0G85AMA6"
          },
          "sensitive_attributes": []
        }
      ]
    },
    {
      "mode": "managed",
      "type": "aws_acm_certificate",
      "name": "cert",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"].us_east_1",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "arn": "arn:aws:acm:us-east-1:756755582140:certificate/b5bb7796-b1e1-41cc-87d6-0e6cbff2da06",
            "certificate_authority_arn": "",
            "certificate_body": null,
            "certificate_chain": null,
            "domain_name": "csv.yuandrk.net",
            "domain_validation_options": [
              {
                "domain_name": "csv.yuandrk.net",
                "resource_record_name": "_e325d4b072baf6fc2cc8e7915df7f241.csv.yuandrk.net.",
                "resource_record_type": "CNAME",
                "resource_record_value": "_8421d50edd2f8960866804ddb373c87e.djqtsrsxkq.acm-validations.aws."
              }
            ],
            "early_renewal_duration": "",
            "id": "arn:aws:acm:us-east-1:756755582140:certificate/b5bb7796-b1e1-41cc-87d6-0e6cbff2da06",
            "key_algorithm": "RSA_2048",
            "not_after": "",
            "not_before": "",
            "options": [
              {
                "certificate_transparency_logging_preference": "ENABLED"
              }
            ],
            "pending_renewal": false,
            "private_key": null,
            "renewal_eligibility": "INELIGIBLE",
            "renewal_summary": [],
            "status": "PENDING_VALIDATION",
            "subject_alternative_names": [
              "csv.yuandrk.net"
            ],
            "tags": null,
            "tags_all": {},
            "type": "AMAZON_ISSUED",
            "validation_emails": [],
            "validation_method": "DNS",
            "validation_option": []
          },
          "sensitive_attributes": [],
          "private": "bnVsbA==",
          "create_before_destroy": true
        }
      ]
    },
    {
      "mode": "managed",
      "type": "aws_acm_certificate_validation",
      "name": "cert_validation",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"].us_east_1",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "certificate_arn": "arn:aws:acm:us-east-1:756755582140:certificate/b5bb7796-b1e1-41cc-87d6-0e6cbff2da06",
            "id": "2024-10-05 15:14:01.088 +0000 UTC",
            "timeouts": null,
            "validation_record_fqdns": [
              "_e325d4b072baf6fc2cc8e7915df7f241.csv.yuandrk.net"
            ]
          },
          "sensitive_attributes": [],
          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjo0NTAwMDAwMDAwMDAwfX0=",
          "dependencies": [
            "aws_acm_certificate.cert",
            "aws_route53_record.cert_validation",
            "data.aws_route53_zone.primary"
          ]
        }
      ]
    },
    {
      "mode": "managed",
      "type": "aws_route53_record",
      "name": "cert_validation",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "index_key": "csv.yuandrk.net",
          "schema_version": 2,
          "attributes": {
            "alias": [],
            "allow_overwrite": null,
            "cidr_routing_policy": [],
            "failover_routing_policy": [],
            "fqdn": "_e325d4b072baf6fc2cc8e7915df7f241.csv.yuandrk.net",
            "geolocation_routing_policy": [],
            "geoproximity_routing_policy": [],
            "health_check_id": "",
            "id": "Z00590051L9DQ0G85AMA6__e325d4b072baf6fc2cc8e7915df7f241.csv.yuandrk.net._CNAME",
            "latency_routing_policy": [],
            "multivalue_answer_routing_policy": false,
            "name": "_e325d4b072baf6fc2cc8e7915df7f241.csv.yuandrk.net",
            "records": [
              "_8421d50edd2f8960866804ddb373c87e.djqtsrsxkq.acm-validations.aws."
            ],
            "set_identifier": "",
            "ttl": 60,
            "type": "CNAME",
            "weighted_routing_policy": [],
            "zone_id": "Z00590051L9DQ0G85AMA6"
          },
          "sensitive_attributes": [],
          "private": "eyJzY2hlbWFfdmVyc2lvbiI6IjIifQ==",
          "dependencies": [
            "aws_acm_certificate.cert",
            "data.aws_route53_zone.primary"
          ]
        }
      ]
    },
    {
      "module": "module.cloudfront",
      "mode": "managed",
      "type": "aws_cloudfront_distribution",
      "name": "s3_distribution",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "aliases": [
              "csv.yuandrk.net"
            ],
            "arn": "arn:aws:cloudfront::756755582140:distribution/E27UQCNC6JWHZK",
            "caller_reference": "terraform-20241005151427454600000002",
            "comment": null,
            "continuous_deployment_policy_id": "",
            "custom_error_response": [],
            "default_cache_behavior": [
              {
                "allowed_methods": [
                  "GET",
                  "HEAD"
                ],
                "cache_policy_id": "",
                "cached_methods": [
                  "GET",
                  "HEAD"
                ],
                "compress": false,
                "default_ttl": 0,
                "field_level_encryption_id": "",
                "forwarded_values": [
                  {
                    "cookies": [
                      {
                        "forward": "none",
                        "whitelisted_names": []
                      }
                    ],
                    "headers": [],
                    "query_string": false,
                    "query_string_cache_keys": []
                  }
                ],
                "function_association": [],
                "lambda_function_association": [],
                "max_ttl": 0,
                "min_ttl": 0,
                "origin_request_policy_id": "",
                "realtime_log_config_arn": "",
                "response_headers_policy_id": "",
                "smooth_streaming": false,
                "target_origin_id": "s3_origin",
                "trusted_key_groups": [],
                "trusted_signers": [],
                "viewer_protocol_policy": "redirect-to-https"
              }
            ],
            "default_root_object": "upload.html",
            "domain_name": "d3hjh3sl3eu49l.cloudfront.net",
            "enabled": true,
            "etag": "EVFR2X6T4YKPB",
            "hosted_zone_id": "Z2FDTNDATAQYW2",
            "http_version": "http2",
            "id": "E27UQCNC6JWHZK",
            "in_progress_validation_batches": 0,
            "is_ipv6_enabled": false,
            "last_modified_time": "2024-10-05 15:14:27.985 +0000 UTC",
            "logging_config": [],
            "ordered_cache_behavior": [],
            "origin": [
              {
                "connection_attempts": 3,
                "connection_timeout": 10,
                "custom_header": [],
                "custom_origin_config": [],
                "domain_name": "csv.yuandrk.net.s3.eu-west-2.amazonaws.com",
                "origin_access_control_id": "",
                "origin_id": "s3_origin",
                "origin_path": "",
                "origin_shield": [],
                "s3_origin_config": [
                  {
                    "origin_access_identity": "origin-access-identity/cloudfront/E1UARH6VZZNE35"
                  }
                ]
              }
            ],
            "origin_group": [],
            "price_class": "PriceClass_All",
            "restrictions": [
              {
                "geo_restriction": [
                  {
                    "locations": [],
                    "restriction_type": "none"
                  }
                ]
              }
            ],
            "retain_on_delete": false,
            "staging": false,
            "status": "Deployed",
            "tags": {
              "Environment": "prod"
            },
            "tags_all": {
              "Environment": "prod"
            },
            "trusted_key_groups": [
              {
                "enabled": false,
                "items": []
              }
            ],
            "trusted_signers": [
              {
                "enabled": false,
                "items": []
              }
            ],
            "viewer_certificate": [
              {
                "acm_certificate_arn": "arn:aws:acm:us-east-1:756755582140:certificate/b5bb7796-b1e1-41cc-87d6-0e6cbff2da06",
                "cloudfront_default_certificate": false,
                "iam_certificate_id": "",
                "minimum_protocol_version": "TLSv1.2_2021",
                "ssl_support_method": "sni-only"
              }
            ],
            "wait_for_deployment": true,
            "web_acl_id": ""
          },
          "sensitive_attributes": [],
          "private": "eyJzY2hlbWFfdmVyc2lvbiI6IjEifQ==",
          "dependencies": [
            "aws_acm_certificate.cert",
            "aws_acm_certificate_validation.cert_validation",
            "aws_route53_record.cert_validation",
            "data.aws_route53_zone.primary",
            "module.cloudfront.aws_cloudfront_origin_access_identity.oai"
          ]
        }
      ]
    },
    {
      "module": "module.cloudfront",
      "mode": "managed",
      "type": "aws_cloudfront_origin_access_identity",
      "name": "oai",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "caller_reference": "terraform-20241005151344583400000001",
            "cloudfront_access_identity_path": "origin-access-identity/cloudfront/E1UARH6VZZNE35",
            "comment": "OAI for CloudFront access to csv.yuandrk.net",
            "etag": "E1Z6C8A9Z72JXW",
            "iam_arn": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E1UARH6VZZNE35",
            "id": "E1UARH6VZZNE35",
            "s3_canonical_user_id": "93264e135ce2699e8bde9301164712206e365b43b2e532c22d7894b57734bdad1e17409f7bd8ae59a4e67916ce2cfd14"
          },
          "sensitive_attributes": [],
          "private": "bnVsbA=="
        }
      ]
    },
    {
      "module": "module.route53",
      "mode": "data",
      "type": "aws_route53_zone",
      "name": "primary",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "arn": "arn:aws:route53:::hostedzone/Z00590051L9DQ0G85AMA6",
            "caller_reference": "RISWorkflow-RD:42f7d6e0-16fe-410b-a1e1-e23c085fc69c",
            "comment": "HostedZone created by Route53 Registrar",
            "id": "Z00590051L9DQ0G85AMA6",
            "linked_service_description": null,
            "linked_service_principal": null,
            "name": "yuandrk.net",
            "name_servers": [
              "ns-58.awsdns-07.com",
              "ns-1895.awsdns-44.co.uk",
              "ns-1352.awsdns-41.org",
              "ns-530.awsdns-02.net"
            ],
            "primary_name_server": "ns-58.awsdns-07.com",
            "private_zone": false,
            "resource_record_set_count": 4,
            "tags": {},
            "vpc_id": null,
            "zone_id": "Z00590051L9DQ0G85AMA6"
          },
          "sensitive_attributes": []
        }
      ]
    },
    {
      "module": "module.route53",
      "mode": "managed",
      "type": "aws_route53_record",
      "name": "cloudfront_alias",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 2,
          "attributes": {
            "alias": [
              {
                "evaluate_target_health": false,
                "name": "d3hjh3sl3eu49l.cloudfront.net",
                "zone_id": "Z2FDTNDATAQYW2"
              }
            ],
            "allow_overwrite": null,
            "cidr_routing_policy": [],
            "failover_routing_policy": [],
            "fqdn": "csv.yuandrk.net",
            "geolocation_routing_policy": [],
            "geoproximity_routing_policy": [],
            "health_check_id": "",
            "id": "Z00590051L9DQ0G85AMA6_csv_A",
            "latency_routing_policy": [],
            "multivalue_answer_routing_policy": false,
            "name": "csv",
            "records": null,
            "set_identifier": "",
            "ttl": 0,
            "type": "A",
            "weighted_routing_policy": [],
            "zone_id": "Z00590051L9DQ0G85AMA6"
          },
          "sensitive_attributes": [],
          "private": "eyJzY2hlbWFfdmVyc2lvbiI6IjIifQ==",
          "dependencies": [
            "aws_acm_certificate.cert",
            "aws_acm_certificate_validation.cert_validation",
            "aws_route53_record.cert_validation",
            "data.aws_route53_zone.primary",
            "module.cloudfront.aws_cloudfront_distribution.s3_distribution",
            "module.cloudfront.aws_cloudfront_origin_access_identity.oai",
            "module.route53.data.aws_route53_zone.primary"
          ]
        }
      ]
    },
    {
      "module": "module.s3",
      "mode": "data",
      "type": "aws_iam_policy_document",
      "name": "s3_policy",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "id": "375213852",
            "json": "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": \"s3:GetObject\",\n      \"Resource\": \"arn:aws:s3:::csv.yuandrk.net/*\",\n      \"Principal\": {\n        \"AWS\": \"arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E1UARH6VZZNE35\"\n      }\n    }\n  ]\n}",
            "minified_json": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::csv.yuandrk.net/*\",\"Principal\":{\"AWS\":\"arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E1UARH6VZZNE35\"}}]}",
            "override_json": null,
            "override_policy_documents": null,
            "policy_id": null,
            "source_json": null,
            "source_policy_documents": null,
            "statement": [
              {
                "actions": [
                  "s3:GetObject"
                ],
                "condition": [],
                "effect": "Allow",
                "not_actions": [],
                "not_principals": [],
                "not_resources": [],
                "principals": [
                  {
                    "identifiers": [
                      "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E1UARH6VZZNE35"
                    ],
                    "type": "AWS"
                  }
                ],
                "resources": [
                  "arn:aws:s3:::csv.yuandrk.net/*"
                ],
                "sid": ""
              }
            ],
            "version": "2012-10-17"
          },
          "sensitive_attributes": []
        }
      ]
    },
    {
      "module": "module.s3",
      "mode": "managed",
      "type": "aws_s3_bucket",
      "name": "bucket_website",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "acceleration_status": "",
            "acl": null,
            "arn": "arn:aws:s3:::csv.yuandrk.net",
            "bucket": "csv.yuandrk.net",
            "bucket_domain_name": "csv.yuandrk.net.s3.amazonaws.com",
            "bucket_prefix": "",
            "bucket_regional_domain_name": "csv.yuandrk.net.s3.eu-west-2.amazonaws.com",
            "cors_rule": [],
            "force_destroy": false,
            "grant": [
              {
                "id": "c3e027793b6cec819d507675f6aca634e1c18a9845ccd33cbf1e781ecab1af5d",
                "permissions": [
                  "FULL_CONTROL"
                ],
                "type": "CanonicalUser",
                "uri": ""
              }
            ],
            "hosted_zone_id": "Z3GKZC51ZF0DB4",
            "id": "csv.yuandrk.net",
            "lifecycle_rule": [],
            "logging": [],
            "object_lock_configuration": [],
            "object_lock_enabled": false,
            "policy": "",
            "region": "eu-west-2",
            "replication_configuration": [],
            "request_payer": "BucketOwner",
            "server_side_encryption_configuration": [
              {
                "rule": [
                  {
                    "apply_server_side_encryption_by_default": [
                      {
                        "kms_master_key_id": "",
                        "sse_algorithm": "AES256"
                      }
                    ],
                    "bucket_key_enabled": false
                  }
                ]
              }
            ],
            "tags": {
              "Environment": "prod"
            },
            "tags_all": {
              "Environment": "prod"
            },
            "timeouts": null,
            "versioning": [
              {
                "enabled": false,
                "mfa_delete": false
              }
            ],
            "website": [],
            "website_domain": null,
            "website_endpoint": null
          },
          "sensitive_attributes": [],
          "private": "eyJlMmJmYjczMC1lY2FhLTExZTYtOGY4OC0zNDM2M2JjN2M0YzAiOnsiY3JlYXRlIjoxMjAwMDAwMDAwMDAwLCJkZWxldGUiOjM2MDAwMDAwMDAwMDAsInJlYWQiOjEyMDAwMDAwMDAwMDAsInVwZGF0ZSI6MTIwMDAwMDAwMDAwMH19"
        }
      ]
    },
    {
      "module": "module.s3",
      "mode": "managed",
      "type": "aws_s3_bucket_ownership_controls",
      "name": "bucket_ownership_controls",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "bucket": "csv.yuandrk.net",
            "id": "csv.yuandrk.net",
            "rule": [
              {
                "object_ownership": "BucketOwnerPreferred"
              }
            ]
          },
          "sensitive_attributes": [],
          "private": "bnVsbA==",
          "dependencies": [
            "module.s3.aws_s3_bucket.bucket_website"
          ]
        }
      ]
    },
    {
      "module": "module.s3",
      "mode": "managed",
      "type": "aws_s3_bucket_policy",
      "name": "bucket_policy",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "bucket": "csv.yuandrk.net",
            "id": "csv.yuandrk.net",
            "policy": "{\"Statement\":[{\"Action\":\"s3:GetObject\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E1UARH6VZZNE35\"},\"Resource\":\"arn:aws:s3:::csv.yuandrk.net/*\"}],\"Version\":\"2012-10-17\"}"
          },
          "sensitive_attributes": [],
          "private": "bnVsbA==",
          "dependencies": [
            "module.cloudfront.aws_cloudfront_origin_access_identity.oai",
            "module.s3.aws_s3_bucket.bucket_website",
            "module.s3.data.aws_iam_policy_document.s3_policy"
          ]
        }
      ]
    },
    {
      "module": "module.s3",
      "mode": "managed",
      "type": "aws_s3_bucket_public_access_block",
      "name": "bucket_public_access_block",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "block_public_acls": true,
            "block_public_policy": true,
            "bucket": "csv.yuandrk.net",
            "id": "csv.yuandrk.net",
            "ignore_public_acls": true,
            "restrict_public_buckets": true
          },
          "sensitive_attributes": [],
          "private": "bnVsbA==",
          "dependencies": [
            "module.s3.aws_s3_bucket.bucket_website"
          ]
        }
      ]
    },
    {
      "module": "module.s3",
      "mode": "managed",
      "type": "aws_s3_object",
      "name": "upload_html",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "acl": "private",
            "arn": "arn:aws:s3:::csv.yuandrk.net/upload.html",
            "bucket": "csv.yuandrk.net",
            "bucket_key_enabled": false,
            "cache_control": "",
            "checksum_algorithm": null,
            "checksum_crc32": "",
            "checksum_crc32c": "",
            "checksum_sha1": "",
            "checksum_sha256": "",
            "content": null,
            "content_base64": null,
            "content_disposition": "",
            "content_encoding": "",
            "content_language": "",
            "content_type": "text/html",
            "etag": "79e3fe1139bdbe27fc02f51171955351",
            "force_destroy": false,
            "id": "upload.html",
            "key": "upload.html",
            "kms_key_id": null,
            "metadata": null,
            "object_lock_legal_hold_status": "",
            "object_lock_mode": "",
            "object_lock_retain_until_date": "",
            "override_provider": [],
            "server_side_encryption": "AES256",
            "source": "./../templates/upload.html",
            "source_hash": null,
            "storage_class": "STANDARD",
            "tags": null,
            "tags_all": {},
            "version_id": "",
            "website_redirect": ""
          },
          "sensitive_attributes": [],
          "private": "bnVsbA==",
          "dependencies": [
            "module.s3.aws_s3_bucket.bucket_website"
          ]
        }
      ]
    }
  ],
  "check_results": null
}

  ```
- terraform.tfstate.backup (182 bytes)
  ```
  {
  "version": 4,
  "terraform_version": "1.5.7",
  "serial": 156,
  "lineage": "c9e42b6c-96f2-7ab4-aab6-c8d148bbcc37",
  "outputs": {},
  "resources": [],
  "check_results": null
}

  ```
- terraform.tfvars (225 bytes)
  ```
  s3_bucket_name         = "csv.yuandrk.net"
acm_certificate_domain = "csv.yuandrk.net"
subdomain_name         = "csv"
domain_name            = "yuandrk.net"
aws_region             = "eu-west-2"
environment            = "prod"

  ```
- variable.tf (626 bytes)
  ```
  variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "acm_certificate_domain" {
  description = "Domain name for the ACM certificate"
  type        = string
}

variable "subdomain_name" {
  description = "Subdomain for the website"
  type        = string
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

  ```

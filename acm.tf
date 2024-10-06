
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

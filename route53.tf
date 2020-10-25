# Route53 Host Zone
resource "aws_route53_zone" "main" {
  name = var.domain[var.env]
}

# SSL Certificate
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain[var.env]
  validation_method = "DNS"
}

# Validation Records
resource "aws_route53_record" "cert_validation" {
  # depends_on = [aws_route53_zone.main]
  # count      = length(aws_acm_certificate.main.domain_validation_options)
  # zone_id    = aws_route53_zone.main.id
  # name       = lookup(aws_acm_certificate.main.domain_validation_options[count.index], "resource_record_name")
  # type       = lookup(aws_acm_certificate.main.domain_validation_options[count.index], "resource_record_type")
  # ttl        = "300"
  # records    = [lookup(aws_acm_certificate.main.domain_validation_options[count.index], "resource_record_value")]

  depends_on = [aws_route53_zone.main]
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.id
}

# Association of ACM Certificate and CNAME Records
resource "aws_acm_certificate_validation" "main" {
  depends_on              = [aws_acm_certificate.main, aws_route53_record.cert_validation]
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for validation_record in aws_route53_record.cert_validation : validation_record.fqdn]
}

# A Record for Load Balancer
resource "aws_route53_record" "a_for_lb" {
  depends_on = [aws_route53_zone.main, aws_lb.app]
  zone_id    = aws_route53_zone.main.id
  name       = var.domain[var.env]
  type       = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}

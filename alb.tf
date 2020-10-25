# Security Group for Load Balancer
resource "aws_security_group" "lb" {
  depends_on = [aws_vpc.vpc]
  vpc_id     = aws_vpc.vpc.id
  tags       = { Name = "${var.env}-${var.project}-lb-sg" }
}

resource "aws_security_group_rule" "lb_outbound_all" {
  depends_on        = [aws_security_group.lb]
  security_group_id = aws_security_group.lb.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "lb_inbound_http" {
  depends_on        = [aws_security_group.lb]
  security_group_id = aws_security_group.lb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "lb_inbound_https" {
  depends_on        = [aws_security_group.lb]
  security_group_id = aws_security_group.lb.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Load Balancer
resource "aws_lb" "app" {
  depends_on         = [aws_security_group.lb, aws_subnet.public_a, aws_subnet.public_c]
  internal           = false
  load_balancer_type = "application"
  # enable_deletion_protection = true # protect from deletion in production
  subnets         = [aws_subnet.public_a.id, aws_subnet.public_c.id]
  security_groups = [aws_security_group.lb.id]
  tags            = { Name = "${var.env}-${var.project}-lb" }
}

# Load Balancer HTTP Listener
resource "aws_lb_listener" "app_http" {
  depends_on        = [aws_lb.app]
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Load Balancer HTTP Listener Rule
resource "aws_lb_listener_rule" "app_http" {
  depends_on   = [aws_lb_listener.app_http]
  listener_arn = aws_lb_listener.app_http.arn
  priority     = 100

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# Load Balancer HTTPS Listener
resource "aws_lb_listener" "app_https" {
  depends_on        = [aws_lb.app, aws_acm_certificate.main, aws_lb_target_group.app]
  load_balancer_arn = aws_lb.app.arn
  certificate_arn   = aws_acm_certificate.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" # default

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Load Balancer HTTP Listener Rule
resource "aws_lb_listener_rule" "app_https" {
  depends_on   = [aws_lb_listener.app_https, aws_lb_target_group.app]
  listener_arn = aws_lb_listener.app_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# Load Balancer Target Group
resource "aws_lb_target_group" "app" {
  depends_on = [aws_vpc.vpc]
  name       = "${var.env}-${var.project}-lb-tg-app"
  vpc_id     = aws_vpc.vpc.id
  port       = 80
  protocol   = "HTTP"

  health_check {
    path     = "/posts"
    protocol = "HTTP"
  }
}

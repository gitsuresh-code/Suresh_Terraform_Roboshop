resource "aws_lb" "frontend-alb" {
  name               = "${local.common_name_suffix}-frontend_alb" # roboshop-dev-frontend-alb
  internal           = true
  load_balancer_type = "application"
  security_groups    = [local.frontend_alb_sg_id]
  # public subnet id
  subnets            = local.public_subnet_ids

  enable_deletion_protection = false # prevents accidental deletion from UI

  tags = merge (
    local.common_tags,
    {
        Name = "${local.common_name_suffix}-frontend-alb"
    }
  )
}

# frontend ALB listening on port number 80
resource "aws_lb_listener" "frontend-alb" {
  load_balancer_arn = local.frontend_alb_listener_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Hi, I am from frontend ALB HTTP"
      status_code  = "200"
    }
  }
}

resource "aws_route53_record" "frontend-alb" {
  zone_id = var.zone_id
  name    = "${var.domain_name}"
  type    = "A"

  alias {
    # These are ALB details, not our domain details
    name                   = aws_lb.frontend-alb.dns_name
    zone_id                = aws_lb.frontend-alb.zone_id
    evaluate_target_health = true
  }
}
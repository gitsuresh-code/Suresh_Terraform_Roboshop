
resource "aws_ssm_parameter" "frontend-alb-listener-arn" {
  name  = "/${var.project_name}/${var.environment}/frontend-alb-listener-arn"
  type  = "String"
  value = aws_lb_listener.frontend-alb.arn
}

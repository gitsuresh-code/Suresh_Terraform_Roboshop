module "sg" {
  count = length(var.sg_names)
  source = "../common_code/sg"
  project_name = var.project_name
  environment = var.environment
  sg_name = var.sg_names[count.index]
  sg_description = "Created for ${var.sg_names[count.index]}"
  vpc_id =  local.vpc_id
}



#Frontend servers accepting traffic from frontend ALB
resource "aws_security_group_rule" "frontend_frontend_alb" {
  type              = "ingress"
  security_group_id = module.sg[9].sg_id # frontend SG ID
  source_security_group_id = module.sg[11].sg_id # frontend ALB SG ID
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
}




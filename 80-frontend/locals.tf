locals {
  common_name_suffix = "${var.project_name}-${var.environment}" # roboshop-dev
  public_subnet_id = split("," , data.aws_ssm_parameter.public_subnet_ids.value)[0]
  public_subnet_ids = split("," , data.aws_ssm_parameter.public_subnet_ids.value)
  ami_id = data.aws_ami.joindevops.id
  frontend_sg_id = data.aws_ssm_parameter.frontend_sg_id.value
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  backend_alb_listener_arn = data.aws_ssm_parameter.backend_alb_listener_arn.value
  common_tags = {
      Project = var.project_name
      Environment = var.environment
      Terraform = "true"
  }
}
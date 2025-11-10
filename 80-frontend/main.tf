# Create EC2 instance
resource "aws_instance" "frontend" {
    ami = local.ami_id
    instance_type = "t3.micro"
    vpc_security_group_ids = [local.frontend_sg_id]
    subnet_id = local.public_subnet_id
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
    tags = merge (
        local.common_tags,
        {
            Name = "${local.common_name_suffix}-frontend" # roboshop-dev-mongodb
        }
    )
}

# Connect to instance using remote-exec provisioner through terraform_data
resource "terraform_data" "frontend" {
  triggers_replace = [
    aws_instance.frontend.id
  ]
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.frontend.private_ip
  }

  # terraform copies this file to frontend server
  provisioner "file" {
    source = "frontend.sh"
    destination = "/tmp/frontend.sh"
  }

    # Configuration will be will done here
  provisioner "remote-exec" {
    inline = [
        "chmod +x /tmp/frontend.sh",
        # "sudo sh /tmp/catalogue.sh"
        "sudo sh /tmp/frontend.sh frontend ${var.environment}"
    ]
  }
}


# stop the instance to take image
resource "aws_ec2_instance_state" "frontend" {
  instance_id = aws_instance.frontend.id
  state       = "stopped"
  depends_on = [terraform_data.frontend]
}

# taking AMI image from existing frontend instance
resource "aws_ami_from_instance" "frontend" {
  name               = "${local.common_name_suffix}-frontend-ami"
  source_instance_id = aws_instance.frontend.id
  depends_on = [aws_ec2_instance_state.frontend]
  tags = merge (
        local.common_tags,
        {
            Name = "${local.common_name_suffix}-frontend-ami" # roboshop-dev-mongodb
        }
  )
}

# creating target group for frontend service
resource "aws_lb_target_group" "frontend" {
  name     = "${local.common_name_suffix}-frontend"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  deregistration_delay = 60 # waiting period before deleting the instance

  health_check {
    healthy_threshold = 2
    interval = 10
    matcher = "200-299"
    path = "/health"
    port = 8080
    protocol = "HTTP"
    timeout = 2
    unhealthy_threshold = 2
  }
}

#launch templates for creating ASG
resource "aws_launch_template" "frontend" {
  name = "${local.common_name_suffix}-frontend"
  image_id = aws_ami_from_instance.frontend.id

  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t3.micro"

  vpc_security_group_ids = [local.frontend_sg_id]

  # tags attached to the instance
  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-frontend"
      }
    )
  }

  # tags attached to the volume created by instance
  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-frontend"
      }
    )
  }

  # tags attached to the launch template
  tags = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-frontend"
      }
  )

}


#creating ASG to scale up/scale down the frontend instances based on traffic
resource "aws_autoscaling_group" "frontend" {
  name                      = "${local.common_name_suffix}-frontend"
  max_size                  = 10
  min_size                  = 1
  health_check_grace_period = 100
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = false
  launch_template {
    id      = aws_launch_template.frontend.id
    version = aws_launch_template.frontend.latest_version
  }
  vpc_zone_identifier       = local.public_subnet_ids
  target_group_arns = [aws_lb_target_group.frontend.arn]
 
  depends_on = [ aws_iam_instance_profile.ec2_instance_profile ]
  dynamic "tag" {  # we will get the iterator with name as tag
    for_each = merge(
      local.common_tags,
      {
        Name = "${local.common_name_suffix}-catalogue"
      }
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  timeouts {
    delete = "15m"
  }

}


resource "aws_autoscaling_policy" "frontend" {
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  name                   = "${local.common_name_suffix}-frontend"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 75.0
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = local.frontend_alb_listener_arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = ["${var.domain_name}"]
    }
  }
}

# resource "terraform_data" "frontend_local" {
#   triggers_replace = [
#     aws_instance.frontend.id
#   ]
  
#   depends_on = [aws_autoscaling_policy.frontend]
#   provisioner "local-exec" {
#     command = "aws ec2 terminate-instances --instance-ids ${aws_instance.frontend.id}"
#   }
# }
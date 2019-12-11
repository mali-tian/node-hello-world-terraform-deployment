# ALB Security Group: Edit to restrict access to the application
resource "aws_security_group" "node_hello_world-lb_security_group" {
  name        = "node-hello-world-load-balancer-security-group"
  description = "controls access to the ALB"
  vpc_id      = "vpc-8c240aeb"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "node_hello_world_ecs_tasks_security_group" {
  name        = "node-hello-world-ecs-tasks-security-group"
  description = "allow inbound access from the ALB only"
  vpc_id      = "vpc-8c240aeb"

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.node_hello_world-lb_security_group.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "aws_region" {
  default = ""
}

variable "aws_profile" {
  default = ""
}

variable "aws_credential_path" {
  default = ""
}

provider "aws" {
  region = var.aws_region
  shared_credentials_file = var.aws_credential_path
  profile = var.aws_profile
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_task_execution_cloudwatch_logs_policy" {
  name = "ecs_task_execution_cloudwatch_logs_policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "ecs_task_execution_policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_lb" "node-hello-world-lb" {
  name               = "node-hello-world-lb-tg"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-04a2ade8b63d1ce61"]
  subnets            = ["subnet-ab1fd1f2", "subnet-d521229c", "subnet-c8ecffaf"]

  enable_deletion_protection = false

  tags = {
    Environment = "test"
  }
}

resource "aws_lb_listener" "node-hello-world-lb-listener" {
  load_balancer_arn = aws_lb.node-hello-world-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node-hello-world-lb-tg.arn
  }
}

resource "aws_lb_target_group" "node-hello-world-lb-tg" {
  name        = "node-hello-world-lb-tg"
  port        = "80"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "vpc-8c240aeb"
}

resource "aws_ecs_cluster" "node-hello-world-terraform" {
  name = "node-hello-world-terraform"
}

resource "aws_ecs_task_definition" "node-hello-world-terraform" {
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  family                   = "hello-world-task-terraform"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = [
      "FARGATE",
  ]
  tags                     = {}
  container_definitions = file("task-definitions/service.json")
}

resource "aws_ecs_service" "node-hello-world-service" {
  name          = "node-hello-world"
  cluster       = aws_ecs_cluster.node-hello-world-terraform.id
  desired_count = 1
  launch_type = "FARGATE"
  task_definition = aws_ecs_task_definition.node-hello-world-terraform.arn
  network_configuration {
    subnets = ["subnet-ab1fd1f2", "subnet-d521229c", "subnet-c8ecffaf"]
    security_groups = ["sg-04a2ade8b63d1ce61"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.node-hello-world-lb-tg.arn
    container_name   = "node-hello-world-terraform"
    container_port   = 3000
  }
  depends_on = [aws_lb_listener.node-hello-world-lb-listener, aws_iam_role.ecs_task_execution_role]
}

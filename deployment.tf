
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

resource "aws_ecs_cluster" "node-hello-world-terraform" {
  name = "node-hello-world-terraform"
}

resource "aws_ecs_task_definition" "node-hello-world-terraform" {
  cpu                      = "256"
  execution_role_arn       = "<ROLE_ARN>"
  family                   = "hello-world-task-terraform"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = [
      "FARGATE",
  ]
  tags                     = {}
  task_role_arn            = "<ROLE_ARN>"
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
}


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
  container_definitions = "${file("task-definitions/service.json")}"

  volume {
    name = "hello-world-storage"

    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
    }
  }
}

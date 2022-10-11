terraform {
  required_version = ">=1.1.9"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.29.0"

    }
  } 
}

// TODO: set remote state. maybe not required?
provider "aws" {
  region = "ap-southeast-2"
  profile = "admin-dev" // TODO: set default profile to use?
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gtd_role" {
  name = "gtdECSTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_cloudwatch_log_group" "gtd_logs" {
  name = "gtd-logs"
}

//TODO: ECS + Fargate to deploy the container app
resource "aws_ecs_cluster" "servian_cluster" {
  name = "servian"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.gtd_logs.name
      }
    }
  }
}

resource "aws_ecs_task_definition" "gtd_task" {
  family = "gtd-task"
  requires_compatibilities = ["FARGATE"]
  cpu = 1024
  memory = 2048
  network_mode = "awsvpc"
  container_definitions = jsonencode(
  [
    {
      name = "gtd-docker-image"
      image = "servian/techchallengeapp:latest"
      essential = true
      memory = 1024
      cpu = 512
      portMappings = [
        {
          containerPort = 3000
          hostPort = 3000
        }
      ]
      command = ["serve"]
      disableNetworking = false
      environment = [
        {
          name = "VTT_LISTENHOST"
          value = "0.0.0.0"
        }
      ]

    }
  ])
  execution_role_arn = aws_iam_role.gtd_role.arn
  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "app" {
  name = "gtd-app"
  cluster = aws_ecs_cluster.servian_cluster.id
  task_definition = aws_ecs_task_definition.gtd_task.arn
  launch_type = "FARGATE"
  desired_count = 1

  network_configuration {
    subnets = data.aws_subnets.default.ids
    assign_public_ip = true
    security_groups = [aws_security_group.gtd_sg.id]
  }

}

// database

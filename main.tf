terraform {
  required_version = ">=1.1.9"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.29.0"

    }
  } 
}

provider "aws" {
  region = "ap-southeast-2"
  profile = "admin-dev" // TODO: set default profile to use?
}

resource "aws_kms_key" "key" {
  description             = "key"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "gtd_logs" {
  name = "gtd-logs"
}

resource "aws_ecs_cluster" "servian_cluster" {
  name = "servian"

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.key.arn
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = true
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
        },
        {
          containerPort = 5432
          hostPort = 5432
        }
      ]
      command = ["serve"]
      disableNetworking = false
      environment =  [
        {
          name = "VTT_DBUSER"
          value = local.db_username
        },
        {
          name = "VTT_DBPASSWORD"
          value = local.db_password
        },
        {
          name = "VTT_DBNAME"
          value = local.db_name
        },
        {
          name = "VTT_DBPORT"
          value = local.db_port
        },
        {
          name = "VTT_DBHOST"
          value = split(":", aws_db_instance.postgresql.endpoint)[0]
        },
        {
          name = "VTT_DBTYPE"
          value = local.db_type
        },
        {
          name = "VTT_LISTENHOST"
          value = local.app_listen_host
        },
        {
          name = "VTT_LISTENPORT"
          value = local.app_listen_port
        }
      ]
      logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-region = "ap-southeast-2"
            awslogs-group = aws_cloudwatch_log_group.gtd_logs.name
            awslogs-stream-prefix = "gtd-app"
          }
      }
    }
  ])
  execution_role_arn = aws_iam_role.gtd_execution_role.arn

  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_task_definition" "updatedb_task" {
  family = "updatedb-task"
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
        },
        {
          containerPort = 5432
          hostport = 5432
        }
      ]
      command = ["updatedb", "-s"]
      disableNetworking = false
      environment =  [
        {
          name = "VTT_DBUSER"
          value = local.db_username
        },
        {
          name = "VTT_DBPASSWORD"
          value = local.db_password
        },
        {
          name = "VTT_DBNAME"
          value = local.db_name
        },
        {
          name = "VTT_DBPORT"
          value = local.db_port
        },
        {
          name = "VTT_DBHOST"
          value = split(":", aws_db_instance.postgresql.endpoint)[0]
        },
        {
          name = "VTT_DBTYPE"
          value = local.db_type
        },
        {
          name = "VTT_LISTENHOST"
          value = local.app_listen_host
        },
        {
          name = "VTT_LISTENPORT"
          value = local.app_listen_port
        }
      ]
      logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-region = "ap-southeast-2"
            awslogs-group = aws_cloudwatch_log_group.gtd_logs.name
            awslogs-stream-prefix = "updatedb"
          }
      }
    }
  ])
  execution_role_arn = aws_iam_role.gtd_execution_role.arn
  task_role_arn = aws_iam_role.gtd_execution_role.arn

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

// After everything has been deployed, manually run updatedb to create the schema and seed the table
resource "null_resource" "bootstrap" {
  triggers = {
    ids = timestamp()
  }
  provisioner "local-exec" {
    command = "aws ecs run-task --cluster ${aws_ecs_cluster.servian_cluster.name} --task-definition ${aws_ecs_task_definition.updatedb_task.arn} --launch-type FARGATE --platform-version '1.4.0' --network-configuration awsvpcConfiguration={subnets=[${join(",", data.aws_subnets.default.ids)}],securityGroups=[${aws_security_group.gtd_sg.id}],assignPublicIp=ENABLED}"
  }

  depends_on = [
    aws_db_instance.postgresql,
    aws_ecs_cluster.servian_cluster,
    aws_ecs_task_definition.updatedb_task
  ]
}

# Cluster
resource "aws_ecs_cluster" "app" {
  name = "${var.env}-${var.project}-cluster-app"
}

# Task Definition
resource "aws_ecs_task_definition" "app" {
  depends_on = [
    aws_ecr_repository.app,
    aws_ecr_repository.webserver,
    aws_db_instance.db,
    null_resource.ecr_image_webserver
  ]
  family                   = "${var.env}-${var.project}-task-app"
  cpu                      = "512"
  memory                   = "512"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]

  volume {
    name = "sockets"

    docker_volume_configuration {
      scope  = "task"
      driver = "local"
    }
  }

  container_definitions = templatefile("./task_definitions/app.json", {
    env                      = var.env,
    project                  = var.project,
    app_repository_url       = aws_ecr_repository.app.repository_url,
    webserver_repository_url = aws_ecr_repository.webserver.repository_url,
    master_key               = var.master_key,
    db_host                  = aws_db_instance.db.address,
    db_username              = var.db_username,
    db_password              = var.db_password,
    log_group_name           = "${var.env}-${var.project}-logs"
  })
}

# Service
resource "aws_ecs_service" "app" {
  depends_on = [
    aws_ecs_cluster.app,
    aws_ecs_task_definition.app,
    aws_iam_role.ecs_service_role,
    aws_lb_target_group.app,
    aws_lb.app # to wait for target group to associate with alb
  ]
  name                               = "${var.env}-${var.project}-service-app"
  cluster                            = aws_ecs_cluster.app.arn
  task_definition                    = aws_ecs_task_definition.app.arn
  launch_type                        = "EC2"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.env}-${var.project}-webserver"
    container_port   = 80
  }
}

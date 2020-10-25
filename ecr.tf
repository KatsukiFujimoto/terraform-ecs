resource "aws_ecr_repository" "app" {
  name                 = "${var.env}-${var.project}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.env}-${var.project}-ecr-app" }
}

resource "aws_ecr_repository" "webserver" {
  name                 = "${var.env}-${var.project}-webserver"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.env}-${var.project}-ecr-webserver" }
}

resource "null_resource" "ecr_image_app" {
  depends_on = [aws_ecr_repository.app]

  provisioner "local-exec" {
    working_dir = var.app_dir
    command     = "aws ecr get-login-password --profile private | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}"
  }

  provisioner "local-exec" {
    working_dir = var.app_dir
    command     = "docker build -t ${var.image_name["app"]} -f ${var.dockerfile_path["app"]} ${var.dockerdir_path["app"]}"
  }

  provisioner "local-exec" {
    working_dir = var.app_dir
    command     = "docker tag ${var.image_name["app"]}:latest ${aws_ecr_repository.app.repository_url}:latest"
  }

  provisioner "local-exec" {
    working_dir = var.app_dir
    command     = "docker push ${aws_ecr_repository.app.repository_url}:latest"
  }
}

resource "null_resource" "ecr_image_webserver" {
  depends_on = [aws_ecr_repository.webserver, null_resource.ecr_image_app]

  provisioner "local-exec" {
    working_dir = var.app_dir
    command     = "aws ecr get-login-password --profile private | docker login --username AWS --password-stdin ${aws_ecr_repository.webserver.repository_url}"
  }

  provisioner "local-exec" {
    working_dir = var.app_dir
    command     = "docker build -t ${var.image_name["webserver"]} -f ${var.dockerfile_path["webserver"]} ${var.dockerdir_path["webserver"]}"
  }

  provisioner "local-exec" {
    working_dir = var.app_dir
    command     = "docker tag ${var.image_name["webserver"]}:latest ${aws_ecr_repository.webserver.repository_url}:latest"
  }

  provisioner "local-exec" {
    working_dir = var.app_dir
    command     = "docker push ${aws_ecr_repository.webserver.repository_url}:latest"
  }
}

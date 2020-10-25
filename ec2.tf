# Security Group
resource "aws_security_group" "app" {
  depends_on = [aws_vpc.vpc]
  vpc_id     = aws_vpc.vpc.id
  tags       = { Name = "${var.env}-${var.project}-app-sg" }
}

resource "aws_security_group_rule" "app_outbound_all" {
  depends_on        = [aws_security_group.app]
  security_group_id = aws_security_group.app.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_inbound_ssh" {
  depends_on        = [aws_security_group.app]
  security_group_id = aws_security_group.app.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_inbound_all" {
  depends_on               = [aws_security_group.app, aws_security_group.lb]
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.lb.id # Allow access from load balancer
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  # cidr_blocks       = ["0.0.0.0/0"] # Allow all access
}

# EC2
resource "aws_instance" "ec2" {
  depends_on = [
    aws_subnet.public_a,
    aws_security_group.app,
    aws_iam_instance_profile.ecs_instance_profile
  ]
  vpc_security_group_ids = [aws_security_group.app.id]
  ami                    = "ami-0fa2ad3f51711653a" # ECS Optimized Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_a.id
  key_name               = var.key_pair
  iam_instance_profile   = aws_iam_instance_profile.ecs_instance_profile.name
  user_data              = templatefile("userdata.sh", { ecs_cluster_name = "${var.env}-${var.project}-cluster-app" })
  tags                   = { Name = "${var.env}-${var.project}-app-ec2" }
}

# Security Group
resource "aws_security_group" "db" {
  depends_on = [aws_vpc.vpc]
  vpc_id     = aws_vpc.vpc.id
  tags       = { Name = "${var.env}-${var.project}-db-sg" }
}

resource "aws_security_group_rule" "db_outbound_all" {
  depends_on        = [aws_security_group.db]
  security_group_id = aws_security_group.db.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "db_inbound_postgres" {
  depends_on               = [aws_security_group.db, aws_security_group.app]
  security_group_id        = aws_security_group.db.id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.env}-${var.project}-db-dg"
  depends_on = [aws_subnet.private_a, aws_subnet.private_c]
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_c.id]
  tags       = { Name = "${var.env}-${var.project}-db-dg" }
}

# RDS
resource "aws_db_instance" "db" {
  depends_on              = [aws_security_group.db, aws_db_subnet_group.main]
  identifier              = "${var.env}-${var.project}-db"
  allocated_storage       = 20 # default
  engine                  = "postgres"
  engine_version          = "12.4"
  instance_class          = "db.t2.micro"
  storage_type            = "gp2" # general purpose SSD which is default
  username                = var.db_username
  password                = var.db_password
  backup_retention_period = 0    # to lessen cost cuz it's private use
  skip_final_snapshot     = true # cuz it's private use
  vpc_security_group_ids  = [aws_security_group.db.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name
  tags                    = { Name = "${var.env}-${var.project}-db" }
}

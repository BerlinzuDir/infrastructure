resource "aws_db_subnet_group" "decilo" {
  name       = "decilo"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "decilo"
  }
}

data "aws_ssm_parameter" "db_username" {
  name = "db_username"
}

data "aws_ssm_parameter" "db_password" {
  name = "db_password"
}

resource "aws_security_group" "rds" {
  name        = "rds"
  description = "security group of rds"
  vpc_id      = var.vpc_id

  tags = {
    Name = "rds"
  }
}

resource "aws_db_instance" "decilo" {
  identifier             = "decilo"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "14"
  username               = data.aws_ssm_parameter.db_username.value
  password               = data.aws_ssm_parameter.db_password.value
  db_subnet_group_name   = aws_db_subnet_group.decilo.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
}

terraform {
  required_version = ">= 0.12"
}

data "aws_vpc" "default" {
#  default = true
   id      = "vpc-09cfd39017fdb66be"
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN SUBNET GROUP ACROSS ALL THE SUBNETS OF THE DEFAULT ASG TO HOST THE RDS INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_db_subnet_group" "example" {
  name       = var.name
  subnet_ids = data.aws_subnet_ids.all.ids

  tags = {
    Name = var.name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A CUSTOM PARAMETER GROUP AND AN OPTION GROUP FOR CONFIGURABILITY
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_db_option_group" "example" {
  name                 = var.name
  engine_name          = var.engine_name
  major_engine_version = var.major_engine_version

  tags = {
    Name = var.name
  }

  option {
    option_name = "MARIADB_AUDIT_PLUGIN"

    option_settings {
      name  = "SERVER_AUDIT_EVENTS"
      value = "CONNECT"
    }
  }
}

resource "aws_db_parameter_group" "example" {
  name   = var.name
  family = var.family

  tags = {
    Name = var.name
  }

  parameter {
    name  = "general_log"
    value = "0"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO THE RDS INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "db_instance" {
  name   = var.name
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "allow_db_access" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  security_group_id = aws_security_group.db_instance.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE DATABASE INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_db_instance" "example" {
  identifier             = var.name
  engine                 = var.engine_name
  engine_version         = var.engine_version
  port                   = var.port
  name                   = var.database_name
  username               = var.username
  password               = var.password
  instance_class         = "db.t2.micro"
  allocated_storage      = var.allocated_storage
  skip_final_snapshot    = true
  license_model          = var.license_model
  db_subnet_group_name   = aws_db_subnet_group.example.id
  vpc_security_group_ids = [aws_security_group.db_instance.id]
  publicly_accessible    = true
  parameter_group_name   = aws_db_parameter_group.example.id
  option_group_name      = aws_db_option_group.example.id

  tags = {
    Name = var.name
  }
}


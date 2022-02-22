########################
## Provider
########################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.2.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile    = "me"
  region     = "us-west-2"
  access_key = "AKIAVQZXNQR5L5A3644U"
  secret_key = "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"
}

provider "aws" {
  alias      = "east"
  profile    = "me"
  region     = "us-east-2"
  access_key = "AKIAVQZXNQR5L5A3644U"
  secret_key = "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"
}

########################
## backend
########################
terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

########################
## Variables
########################

variable "environment_name" {
  description = "The name of the environment"
  default     = "minor-version-upgrade-test"
}

variable "primary_vpc_id" {
  description = "The ID of the VPC that the RDS cluster will be created in"
  default     = "vpc-e170ec84"
}

variable "secondary_vpc_id" {
  description = "The ID of the VPC that the RDS cluster will be created in"
  default     = "vpc-e170ec84"
}

variable "vpc_name" {
  description = "The name of the VPC that the RDS cluster will be created in"
  default     = "default_vpc"
}

variable "vpc_rds_subnet_ids_primary" {
  description = "The ID's of the VPC subnets that the primary RDS cluster instances will be created in"
  default     = ["subnet-0b623dbc239276272", "subnet-0702e93e7560be291"]
}

variable "vpc_rds_subnet_ids_secondary" {
  description = "The ID's of the VPC subnets that the secondary RDS cluster instances will be created in"
  default     = ["subnet-f717d58c", "subnet-ae8661e3"]
}

variable "vpc_rds_security_group_id" {
  description = "The ID of the security group that should be used for the RDS cluster instances"
  default     = "sg-d948c5a3"
}

variable "vpc_rds_security_group_id_secondary" {
  description = "The ID of the security group that should be used for the RDS cluster instances"
  default     = "sg-0d2d3055f2d093aac"
}

variable "rds_master_username" {
  description = "The ID's of the VPC subnets that the RDS cluster instances will be created in"
  default     = "jonas"
}

variable "rds_master_password" {
  description = "The ID's of the VPC subnets that the RDS cluster instances will be created in"
  default     = "password123456789"
}


variable "rds_engine" {
  description = "The postgres major and minor version"
  default     = "aurora-postgresql"
}

variable "rds_engine_version" {
  description = "The postgres major and minor version"
  default     = "11.7"
}

########################
## Cluster
########################
resource "aws_rds_global_cluster" "aurora_cluster_global" {
  global_cluster_identifier = "global-minorVersionUpgradeTest"
  engine                    = "aurora-postgresql"
  engine_version            = var.rds_engine_version
  database_name             = "minorVersionUpgradeTest-global"
}

resource "aws_rds_cluster" "aurora_cluster_primary" {

  cluster_identifier           = "${var.environment_name}-aurora-cluster-primary"
  global_cluster_identifier    = aws_rds_global_cluster.aurora_cluster_global.id
  engine                       = aws_rds_global_cluster.aurora_cluster_global.engine
  engine_version               = aws_rds_global_cluster.aurora_cluster_global.engine_version
  database_name                = "minorVersionUpgradeTestClusterPrimary"
  master_username              = var.rds_master_username
  master_password              = var.rds_master_password
  backup_retention_period      = 14
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "wed:03:00-wed:04:00"
  db_subnet_group_name         = aws_db_subnet_group.aurora_subnet_group_primary.name
  final_snapshot_identifier    = "${var.environment_name}-aurora-cluster-secondary"
  vpc_security_group_ids = [
    "${var.vpc_rds_security_group_id}"
  ]

  tags = {
    Name        = "${var.environment_name}-Aurora-DB-Cluster"
    VPC         = "${var.vpc_name}"
    ManagedBy   = "terraform"
    Environment = "${var.environment_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_rds_cluster_instance" "aurora_cluster_instance_primary" {

  count                = length(var.vpc_rds_subnet_ids_primary)
  engine               = aws_rds_global_cluster.aurora_cluster_global.engine
  engine_version       = aws_rds_global_cluster.aurora_cluster_global.engine_version
  identifier           = "${var.environment_name}-aurora-instance-primary-${count.index}"
  cluster_identifier   = aws_rds_cluster.aurora_cluster_primary.id
  instance_class       = "db.r4.large"
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group_primary.name
  publicly_accessible  = true

  tags = {
    Name        = "${var.environment_name}-Aurora-DB-Instance-${count.index}"
    VPC         = "${var.vpc_name}"
    ManagedBy   = "terraform"
    Environment = "${var.environment_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_rds_cluster" "aurora_cluster_secondary" {

  cluster_identifier           = "${var.environment_name}-aurora-cluster-secondary"
  global_cluster_identifier    = aws_rds_global_cluster.aurora_cluster_global.id
  engine                       = aws_rds_global_cluster.aurora_cluster_global.engine
  engine_version               = aws_rds_global_cluster.aurora_cluster_global.engine_version
  provider                     = aws.east
  backup_retention_period      = 14
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "wed:03:00-wed:04:00"
  db_subnet_group_name         = aws_db_subnet_group.aurora_subnet_group_secondary.name
  final_snapshot_identifier    = "${var.environment_name}-aurora-cluster-secondary"
  vpc_security_group_ids = [
    "${var.vpc_rds_security_group_id_secondary}"
  ]

  tags = {
    Name        = "${var.environment_name}-Aurora-DB-Cluster-secondary"
    VPC         = "${var.vpc_name}"
    ManagedBy   = "terraform"
    Environment = "${var.environment_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_rds_cluster_instance.aurora_cluster_instance_primary
  ]

}

resource "aws_rds_cluster_instance" "aurora_cluster_instance_secondary" {

  count                = length(var.vpc_rds_subnet_ids_secondary)
  engine               = aws_rds_global_cluster.aurora_cluster_global.engine
  engine_version       = aws_rds_global_cluster.aurora_cluster_global.engine_version
  provider             = aws.east
  identifier           = "${var.environment_name}-aurora-instance-secondary-${count.index}"
  cluster_identifier   = aws_rds_cluster.aurora_cluster_secondary.id
  instance_class       = "db.r4.large"
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group_secondary.name
  publicly_accessible  = true

  tags = {
    Name        = "${var.environment_name}-Aurora-DB-Instance-secondary-${count.index}"
    VPC         = "${var.vpc_name}"
    ManagedBy   = "terraform"
    Environment = "${var.environment_name}"
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_db_subnet_group" "aurora_subnet_group_primary" {

  name        = "${var.environment_name}_aurora_db_subnet_group_primary"
  description = "Allowed subnets for Aurora DB cluster instances"
  subnet_ids  = var.vpc_rds_subnet_ids_primary

  tags = {
    Name        = "${var.environment_name}-Aurora-DB-Subnet-Group-primary"
    VPC         = "${var.vpc_name}"
    ManagedBy   = "terraform"
    Environment = "${var.environment_name}"
  }

}

resource "aws_db_subnet_group" "aurora_subnet_group_secondary" {

  provider    = aws.east
  name        = "${var.environment_name}_aurora_db_subnet_group_secondary"
  description = "Allowed subnets for Aurora DB cluster instances"
  subnet_ids  = var.vpc_rds_subnet_ids_secondary

  tags = {
    Name        = "${var.environment_name}-Aurora-DB-Subnet-Group-secondary"
    VPC         = "${var.vpc_name}"
    ManagedBy   = "terraform"
    Environment = "${var.environment_name}"
  }

}

########################
## Output
########################

output "primary_cluster_address" {
  value = aws_rds_cluster.aurora_cluster_primary.endpoint
}

output "secondary_cluster_address" {
  value = aws_rds_cluster.aurora_cluster_secondary.endpoint
}

# Create RDS VPC
resource "aws_vpc" "rds" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "rds-vpc"
  }
}
# Create RDS Subnet
resource "aws_subnet" "rds-a" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.20.10.0/24"
  availability_zone                           = "eu-central-1a"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "rds-a"
  }
}
resource "aws_subnet" "rds-b" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.20.11.0/24"
  availability_zone                           = "eu-central-1b"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "rds-b"
  }
}
resource "aws_subnet" "rds-c" {
  vpc_id                                      = aws_vpc.rds.id
  cidr_block                                  = "10.20.12.0/24"
  availability_zone                           = "eu-central-1c"
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "rds-c"
  }
}


resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.rds.id
  ingress {
    from_port = 1433
    to_port   = 1433
    protocol  = "tcp"
    self      = true
  }
  egress {
    from_port = 1433
    to_port   = 1433
    protocol  = "tcp"
    self      = true
  }
  tags = {
    Name = "rds-sg"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.rds-a.id, aws_subnet.rds-b.id, aws_subnet.rds-c.id]
  tags = {
    Name = "rds-subnet-group"
  }
}

# Virtual Private Gateway
resource "aws_vpn_gateway" "rds" {
  vpc_id = aws_vpc.rds.id
  tags = {
    Name = "Azure-VPN-Gateway"
  }
}

# Attach gateway to vpc
resource "aws_vpn_gateway_attachment" "rds" {
  vpc_id         = aws_vpc.rds.id
  vpn_gateway_id = aws_vpn_gateway.rds.id
}

# Customer Gateway
resource "aws_customer_gateway" "rds" {
  bgp_asn    = 65000
  ip_address = var.azure_public_vpn_ip
  type       = "ipsec.1"
  tags = {
    Name = "Azure-VPN-Gateway"
  }
}

resource "aws_vpn_connection" "rds" {
  customer_gateway_id = aws_customer_gateway.rds.id
  vpn_gateway_id      = aws_vpn_gateway.rds.id
  type                = "ipsec.1"
  static_routes_only  = true
  tags = {
    Name = "Azure-VPN-Gateway"
  }
}

module "database_migration_service" {
  source  = "terraform-aws-modules/dms/aws"
  version = "~> 2.0"

  # Subnet group
  repl_subnet_group_name        = "example"
  repl_subnet_group_description = "DMS Subnet group"
  repl_subnet_group_subnet_ids  = [aws_subnet.rds-a.id, aws_subnet.rds-b.id, aws_subnet.rds-c.id]

  # Instance
  repl_instance_allocated_storage            = 64
  repl_instance_auto_minor_version_upgrade   = true
  repl_instance_allow_major_version_upgrade  = true
  repl_instance_apply_immediately            = true
  repl_instance_engine_version               = "3.5.2"
  repl_instance_multi_az                     = true
  repl_instance_preferred_maintenance_window = "sun:10:30-sun:14:30"
  repl_instance_publicly_accessible          = false
  repl_instance_class                        = "dms.t3.large"
  repl_instance_id                           = "example"
  repl_instance_vpc_security_group_ids       = [aws_subnet.rds-a.id, aws_subnet.rds-b.id, aws_subnet.rds-c.id]

  endpoints = {
    source = {
      database_name               = "example"
      endpoint_id                 = "example-source"
      endpoint_type               = "source"
      engine_name                 = "mysql"
      extra_connection_attributes = "heartbeatFrequency=1;"
      username                    = "mysqlUser"
      password                    = var.mssql_password
      port                        = 1433
      server_name                 = "dms"
      ssl_mode                    = "none"
      tags                        = { EndpointType = "source" }
    }

    destination = {
      database_name = "example"
      endpoint_id   = "example-destination"
      endpoint_type = "target"
      engine_name   = "mysql"
      username      = "mssqluser"
      password      = "passwordsDoNotNeedToMatch789?"
      port          = 3306
      server_name   = "dms-ex-dest.cluster-abcdefghijkl.us-east-1.rds.amazonaws.com"
      ssl_mode      = "none"
      tags          = { EndpointType = "destination" }
    }
  }

  replication_tasks = {
    cdc_ex = {
      replication_task_id       = "example-cdc"
      migration_type            = "cdc"
      replication_task_settings = file("task_settings.json")
      table_mappings            = file("table_mappings.json")
      source_endpoint_key       = "source"
      target_endpoint_key       = "destination"
      tags                      = { Task = "PostgreSQL-to-MySQL" }
    }
  }

  event_subscriptions = {
    instance = {
      name                             = "instance-events"
      enabled                          = true
      instance_event_subscription_keys = ["example"]
      source_type                      = "replication-instance"
      sns_topic_arn                    = "arn:aws:sns:us-east-1:012345678910:example-topic"
      event_categories = [
        "failure",
        "creation",
        "deletion",
        "maintenance",
        "failover",
        "low storage",
        "configuration change"
      ]
    }
    task = {
      name                         = "task-events"
      enabled                      = true
      task_event_subscription_keys = ["cdc_ex"]
      source_type                  = "replication-task"
      sns_topic_arn                = "arn:aws:sns:us-east-1:012345678910:example-topic"
      event_categories = [
        "failure",
        "state change",
        "creation",
        "deletion",
        "configuration change"
      ]
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

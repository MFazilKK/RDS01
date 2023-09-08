provider "aws" {
  region = "us-east-1" # Change this to your desired AWS region
}

resource "aws_rds_cluster" "example" {
  cluster_identifier      = "my-cluster"
  availability_zones     = ["us-east-1a", "us-east-1b"]
  master_username         = "admin"
  master_password         = "mysecretpassword"
  skip_final_snapshot     = true
  backup_retention_period = 7

  # Specify the database engine
  engine = "aurora-mysql" # Change this to the desired engine type
}

# Create an RDS Cluster Snapshot
resource "aws_db_cluster_snapshot" "example_snapshot" {
  db_cluster_identifier = aws_rds_cluster.example.id
  db_cluster_snapshot_identifier = "my-cluster-snapshot"
  tags = {
    Name = "MyClusterSnapshot"
  }
}

# Prevent the RDS Cluster Snapshot from being publicly accessible
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.example.default_network_acl_id
}

resource "aws_network_acl_rule" "egress" {
  network_acl_id = aws_default_network_acl.default.id
  rule_number    = 200
  rule_action    = "allow"
  protocol       = "-1"
  cidr_block     = "0.0.0.0/0"
  egress         = true
}

resource "aws_network_acl_rule" "ingress" {
  network_acl_id = aws_default_network_acl.default.id
  rule_number    = 100
  rule_action    = "deny"
  protocol       = "-1"
  cidr_block     = "0.0.0.0/0"
  egress         = false
}

# Add a rule to explicitly deny public access to the snapshot
resource "aws_network_acl_rule" "deny_public_access" {
  network_acl_id = aws_default_network_acl.default.id
  rule_number    = 110
  rule_action    = "deny"
  protocol       = "-1"
  cidr_block     = "0.0.0.0/0"
  egress         = false
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

# Attach the network ACL to the VPC
resource "aws_default_route_table" "example" {
  default_route_table_id = aws_vpc.example.default_route_table_id
}

resource "aws_network_acl_association" "example" {
  subnet_id          = aws_subnet.example.id
  network_acl_id     = aws_default_network_acl.default.id
}

resource "aws_subnet" "example" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

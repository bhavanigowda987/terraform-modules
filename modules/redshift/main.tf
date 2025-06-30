resource "aws_security_group" "redshift_sg" {
  name        = "redshift-sg"
  description = "Allow Redshift access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_redshift_subnet_group" "this" {
  name       = "redshift-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_redshift_cluster" "this" {
  cluster_identifier        = var.cluster_identifier
  node_type                 = var.node_type
  number_of_nodes           = var.number_of_nodes
  database_name             = var.database_name
  master_username           = var.master_username
  master_password           = var.master_password
  cluster_subnet_group_name = aws_redshift_subnet_group.this.name
  vpc_security_group_ids    = [aws_security_group.redshift_sg.id]
  publicly_accessible       = false
  skip_final_snapshot       = true

 
}


resource "aws_security_group" "db_vm_sg" {
  name        = "${var.cluster_name}-db-vm-sg"
  description = "Security group for database VM instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.management_ip_cidr]
    description = "SSH access from management IP"
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
    description     = "MySQL access from EKS application pods"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-db-vm-sg"
    }
  )
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access from anywhere"
  }

  egress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
    description     = "Allow traffic only to app pods on port 8080"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-alb-sg"
    }
  )

  depends_on = [
    aws_security_group.app_sg
  ]
}

resource "aws_security_group" "app_sg" {
  name        = "${var.cluster_name}-app-sg"
  description = "Security group for application pods in Kubernetes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Allow traffic from ALB on container port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-app-sg"
    }
  )
}

data "aws_ami" "ubuntu_2004" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "db_vm" {
  ami                         = data.aws_ami.ubuntu_2004.id
  instance_type               = "t3.small"
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.db_vm_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.db_vm_instance_profile.name
  associate_public_ip_address = true

  # VM configuration script
  user_data = <<-EOF
    #!/bin/bash

    # Log output
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    echo "Starting init script..."
    sleep 30

    echo "Checking for pkg lock..."
    max_attempts=30
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
      if apt-get update -qq &> /dev/null; then
        echo "Package manager is available. Proceeding..."
        break
      fi

      if [ $attempt -eq $((max_attempts-1)) ]; then
        echo "Package manager not available after $max_attempts attempts. Exiting..."
        exit 1
      fi

      ((attempt++))
      echo "Attempt $attempt/$max_attempts: Waiting for package manager to be available..."
      sleep 5
    done

    echo "Starting mysql installation..."

    # Install mysql and aws cli with non-interactive frontend
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server awscli

    # Configure MySQL for external access and enable legacy auth
    sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
    echo "default_authentication_plugin=mysql_native_password" >> /etc/mysql/mysql.conf.d/mysqld.cnf

    # Restart mysql to apply changes
    echo "Restarting mysql service..."
    systemctl restart mysql

    # Create database and user
    echo "Creating database and user..."
    mysql -u root << MYSQL_SCRIPT
    CREATE DATABASE IF NOT EXISTS ${var.app_name};
    CREATE USER '${var.app_name}'@'%' IDENTIFIED WITH mysql_native_password BY '${var.db_password}';
    GRANT ALL PRIVILEGES ON ${var.app_name}.* TO '${var.app_name}'@'%';
    FLUSH PRIVILEGES;
    MYSQL_SCRIPT

    # Create backup script
    echo "Creating backup script..."
    cat > /usr/local/bin/backup_mysql.sh << 'BACKUPSCRIPT'
    #!/bin/bash

    # Variables
    DB_NAME="${var.app_name}"
    BACKUP_PATH="/tmp/mysql_backup"
    DATETIME=$(date +%Y%m%d-%H%M%S)
    BACKUP_FILENAME="$${DB_NAME}-$${DATETIME}.sql"
    S3_BUCKET="${var.bucket_name}"
    S3_KEY="backups/mysql/$${BACKUP_FILENAME}"

    # Create backup directory
    mkdir -p $${BACKUP_PATH}

    # Dump the database
    mysqldump -u root $${DB_NAME} > $${BACKUP_PATH}/$${BACKUP_FILENAME}
    aws s3 cp $${BACKUP_PATH}/$${BACKUP_FILENAME} s3://$${S3_BUCKET}/$${S3_KEY}
    rm -f $${BACKUP_PATH}/$${BACKUP_FILENAME}

    # Keep the last 7 backups in S3
    OLD_BACKUPS=$(aws s3 ls s3://$${S3_BUCKET}/backups/mysql/ | sort | head -n -7 | awk '{print $4}')
    for OLD_BACKUP in $${OLD_BACKUPS}; do
      aws s3 rm s3://$${S3_BUCKET}/backups/mysql/$${OLD_BACKUP}
    done
    BACKUPSCRIPT

    # Schedule cronjob for backup
    chmod +x /usr/local/bin/backup_mysql.sh
    echo "0 */4 * * * /usr/local/bin/backup_mysql.sh > /var/log/mysql/backup.log 2>&1" | crontab -
    echo "Done!"
  EOF

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional" # IMDSv1 misconfiguration
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_size           = var.node_group_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-db-vm"
    }
  )
}

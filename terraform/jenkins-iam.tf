resource "aws_iam_role" "jenkins" {
  name = "${var.project}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-jenkins-role"
    Environment = var.environment
    Project     = var.project
    Service     = "jenkins"
  }
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project}-jenkins-profile"
  role = aws_iam_role.jenkins.name

  tags = {
    Name        = "${var.project}-jenkins-profile"
    Environment = var.environment
    Project     = var.project
    Service     = "jenkins"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.jenkins_instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name               = var.jenkins_key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name

  associate_public_ip_address = true
  user_data_replace_on_change = true
  root_block_device {
    volume_size = var.jenkins_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
  #!/bin/bash

  set -euxo pipefail

  exec > >(tee -a /var/log/shopsphere-user-data.log | logger -t shopsphere-user-data -s 2>/dev/console) 2>&1

  export DEBIAN_FRONTEND=noninteractive

  echo "===== ShopSphere Jenkins bootstrap started ====="

  apt-get update

  echo "===== Installing base packages ====="

  apt-get install -y \
    ca-certificates \
    curl \
    wget \
    gnupg \
    git \
    unzip \
    fontconfig \
    openjdk-21-jre \
    openjdk-17-jdk \
    maven

  echo "===== Java versions ====="

  java -version
  /usr/lib/jvm/java-17-openjdk-amd64/bin/java -version

  echo "===== Maven ====="

  mvn -version

  echo "===== Installing Docker ====="

  install -m 0755 -d /etc/apt/keyrings

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

  chmod a+r /etc/apt/keyrings/docker.asc

  cat > /etc/apt/sources.list.d/docker.sources <<'DOCKERREPO'
  Types: deb
  URIs: https://download.docker.com/linux/ubuntu
  Suites: noble
  Components: stable
  Architectures: amd64
  Signed-By: /etc/apt/keyrings/docker.asc
  DOCKERREPO

  apt-get update

  apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  systemctl enable docker
  systemctl start docker

  docker --version
  docker compose version

  echo "===== Installing Trivy ====="

  mkdir -p /usr/share/keyrings

  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
    gpg --dearmor | \
    tee /usr/share/keyrings/trivy.gpg > /dev/null

  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
    > /etc/apt/sources.list.d/trivy.list

  apt-get update

  apt-get install -y trivy

  trivy --version

  echo "===== Installing Jenkins repository ====="

  mkdir -p /etc/apt/keyrings

  wget -O /etc/apt/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

  echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
    > /etc/apt/sources.list.d/jenkins.list

  apt-get update

  echo "===== Installing Jenkins ====="

  apt-get install -y jenkins

  echo "===== Jenkins Docker permissions ====="

  usermod -aG docker jenkins

  echo "===== Starting Jenkins ====="

  systemctl daemon-reload
  systemctl enable jenkins
  systemctl restart jenkins

  echo "===== Jenkins status ====="

  systemctl --no-pager --full status jenkins || true

  echo "===== Docker status ====="

  systemctl --no-pager --full status docker || true

  echo "===== Installed tool versions ====="

  echo "--- Java ---"
  java -version

  echo "--- JDK 17 ---"
  /usr/lib/jvm/java-17-openjdk-amd64/bin/java -version

  echo "--- Maven ---"
  mvn -version

  echo "--- Docker ---"
  docker --version

  echo "--- Trivy ---"
  trivy --version

  echo "--- Git ---"
  git --version

  echo "===== ShopSphere Jenkins bootstrap completed ====="
EOF

  tags = {
    Name        = "${var.project}-jenkins"
    Environment = var.environment
    Project     = var.project
    Service     = "jenkins"
  }
}

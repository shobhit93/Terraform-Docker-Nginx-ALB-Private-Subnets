# security group for EC2 instances
resource "aws_security_group" "docker_demo_ec2" {
  name        = "docker-nginx-demo-ec2"
  description = "allow incoming HTTP traffic only"
  vpc_id      = aws_vpc.demo.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  public_key_filename  = "${var.path}/${var.key_name}.pub"
  private_key_filename = "${var.path}/${var.key_name}.pem"
}

resource "tls_private_key" "algorithm" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.algorithm.public_key_openssh
}
resource "local_file" "public_key_openssh" {
  count    = var.path != "" ? 1 : 0
  content  = tls_private_key.algorithm.public_key_openssh
  filename = local.public_key_filename
}

resource "local_file" "private_key_pem" {
  count    = var.path != "" ? 1 : 0
  content  = tls_private_key.algorithm.private_key_pem
  filename = local.private_key_filename
}

resource "null_resource" "chmod" {
  count      = var.path != "" ? 1 : 0
  depends_on = [local_file.private_key_pem]

  triggers = {
    key = tls_private_key.algorithm.private_key_pem
  }
}

# EC2 instances, one per availability zone in private subnet
resource "aws_instance" "docker_demo" {
  ami                         = var.ec2_amis
  associate_public_ip_address = true
  depends_on 				  = [ aws_route.private_nat_gateway_route, aws_subnet.private ] 
  instance_type               = "t2.micro"
  key_name 					  = aws_key_pair.generated_key.key_name
  subnet_id                   = aws_subnet.private.id
  
  # references security group created above
  vpc_security_group_ids = [aws_security_group.docker_demo_ec2.id]

  tags = {
    Name = "docker-nginx-demo-instance"
  }
}

# EC2 instances, bastion host in public subnet to configure private instance
resource "aws_instance" "bastion_host" {
  ami                         = var.ec2_amis
  associate_public_ip_address = true
  depends_on                  = [aws_subnet.public]
  instance_type               = "t2.micro"
  key_name 				      = aws_key_pair.generated_key.key_name
  subnet_id                   = aws_subnet.public.*.id[0]

  # references security group created above
  vpc_security_group_ids = [aws_security_group.docker_demo_ec2.id]

  tags = {
    Name = "bastion-host"
  }
}

#copying file to private instance and running the docker image with custom config
resource "null_resource" "Provisioner" {

	connection {
		agent = false
		bastion_host = aws_instance.bastion_host.public_ip
		bastion_user = "ubuntu"
		bastion_port = 22
		bastion_private_key = file(local.private_key_filename)
		user = "ubuntu"
		private_key = file(local.private_key_filename)
		host = aws_instance.docker_demo.private_ip
		timeout = "2m"
	}
	
	provisioner "file" {
	source      = "site-content"
	destination = "~/site-content"
	}	
	
    provisioner "remote-exec" {
        inline = [
		"curl -fsSL https://get.docker.com -o get-docker.sh",
		"sudo sh get-docker.sh",
		# pull nginx image
		"sudo docker pull nginx:latest",
        "sudo docker run -it --rm -d -p 80:80 --name web -v /home/ubuntu/site-content:/usr/share/nginx/html/index.html nginx"
      ]
    }
}
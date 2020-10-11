# security group for application load balancer
resource "aws_security_group" "docker_demo_alb_sg" {
  name        = "docker-nginx-demo-alb-sg"
  description = "allow incoming HTTP traffic only"
  vpc_id      = aws_vpc.demo.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "alb-security-group-docker-demo"
  }
}

# using ALB - instances in private subnets
resource "aws_alb" "docker_demo_alb" {
  name            = "docker-demo-alb-private"
  security_groups = [aws_security_group.docker_demo_alb_sg.id]
  subnets         = aws_subnet.public.*.id
  tags = {
    Name = "docker-demo-alb"
  }
}

# alb target group
resource "aws_alb_target_group" "docker-demo-tg" {
  name     = "docker-demo-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo.id
  health_check {
    path = "/"
    port = 80
  }
}

# listener
resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = aws_alb.docker_demo_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.docker-demo-tg.arn
    type             = "forward"
  }
}

# target group attach
# using nested interpolation functions and the count parameter to the "aws_alb_target_group_attachment"
resource "aws_lb_target_group_attachment" "docker-demo" {
  count            = length(data.aws_availability_zones.available.names)
  target_group_arn = aws_alb_target_group.docker-demo-tg.arn
  target_id = element(
    split(",", join(",", aws_instance.docker_demo.*.id)),
    count.index,
  )
  port = 80
}

resource "aws_route53_zone" "main" {
  name = "shobhitprivateroute.com"
}

resource "aws_route53_record" "main" {
  allow_overwrite = true
  name            = "shobhitprivateroute.com"
  ttl             = 30
  type            = "NS"
  zone_id         = aws_route53_zone.main.zone_id

  records = [
    aws_route53_zone.main.name_servers[0],
    aws_route53_zone.main.name_servers[1],
    aws_route53_zone.main.name_servers[2],
    aws_route53_zone.main.name_servers[3],
  ]
}

resource "aws_route53_record" "assesment" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "assessment.shobhitprivateroute.com"
  type    = "A"
  alias {
    name                   = "dualstack.${aws_alb.docker_demo_alb.dns_name}"
    zone_id                = aws_alb.docker_demo_alb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.shobhitprivateroute.com"
  type    = "A"
  alias {
    name                   = "dualstack.${aws_alb.docker_demo_alb.dns_name}"
    zone_id                = aws_alb.docker_demo_alb.zone_id
    evaluate_target_health = false
  }
}
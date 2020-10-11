output "key_name" {
  value = aws_key_pair.generated_key.key_name
}

output "public_key_filepath" {
  value = local.public_key_filename
}

output "private_key_filepath" {
  value = local.private_key_filename
}

# ALB DNS is generated dynamically, return URL so that it can be used
output "alb_url" {
  value = "http://${aws_alb.docker_demo_alb.dns_name}/"
}

#route53 url
output "Domain_Url" {
  value = "http://${aws_route53_record.www.name}/"
}

output "id" {
  description = "Instances ID"
  value       = aws_instance.docker_demo.id
}

output "private_instance_ip" {
  description = "private IP addresses assigned to the instances"
  value       = aws_instance.docker_demo.private_ip
}

output "private_subnet_id" {
  description = "List of IDs of private subnet"
  value       = aws_subnet.private.id
}

output "public_subnet_id" {
  description = "List of IDs of public subnet"
  value       = aws_subnet.public.*.id
}
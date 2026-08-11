output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.main.endpoint
}

output "s3_website_url" {
  description = "URL of the S3 static website"
  value       = "http://${aws_s3_bucket.static.bucket}.s3-website-${var.aws_region}.amazonaws.com"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.static.bucket
}

output "ssh_key_path" {
  description = "Path to the generated SSH private key"
  value       = local_file.private_key.filename
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "db_identifier" {
  description = "RDS database identifier"
  value       = aws_db_instance.main.identifier
}

output "route53_nameservers" {
  description = "Route 53 name servers (if domain provided)"
  value       = var.domain_name != "" ? aws_route53_zone.main[0].name_servers : []
}

variable "my_name" {
  description = "Your name or identifier (used for all resource naming)"
  type        = string
  default     = "nkechi"
}

variable "aws_region" {
  description = "AWS region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "db_password" {
  description = "RDS master password (min 8 chars, must include uppercase, lowercase, number, symbol)"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Your registered domain name (optional — leave empty to skip Route 53)"
  type        = string
  default     = ""
}

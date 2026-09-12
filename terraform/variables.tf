variable "aws_region" {
  description = "AWS region for the fraud detection platform"
  type        = string
  default     = "ap-south-1"
}
variable "db_password" {
  description = "MySQL database password"
  type        = string
  sensitive   = true
}

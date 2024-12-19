variable "region" {
    default = "eu-central-1"
}

variable "aws_access_key" {
  type        = string
  sensitive   = true
  description = "AWS Administrator Access Key"
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
  description = "AWS Administrator Secret Key"
}

variable "az1" {
  description = "First zone"
  default     = "eu-central-1a"
}

variable "az2" {
  description = "Second zone"
  default     = "eu-central-1b"
}

variable "prefix" {
  default = "azi"
}

variable "public_key_path" {
  description = "SSH pub key"
  type        = string
  default     = "./key.pub"
}
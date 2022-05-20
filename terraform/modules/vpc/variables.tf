variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block of VPC"
}

variable "region" {
  type        = string
  description = "Region of module"
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  description = "List of public subnet CIDR blocks"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

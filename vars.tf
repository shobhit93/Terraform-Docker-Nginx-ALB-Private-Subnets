# Put the following two keys into shell or env variables

#variable "aws_access_key" {
#  description = "AWS access key, must pass on command line using -var"
#}

#variable "aws_secret_key" {
#  description = "AWS secret access key, must pass on command line using -var"
#}

variable "aws_region" {
  description = "US WEST"
  default     = "us-west-1"
}

# dynamically retrieves all availability zones for current region
#data "aws_availability_zones" "available" {}

variable "ec2_amis" {
  description = "Ubuntu Server 18.04 LTS (HVM)"
  default     = "ami-03fac5402e10ea93b"
}

variable "public_subnets_cidr" {
  type    = list(string)
  default = ["192.168.1.0/26", "192.168.1.64/26"]
}

variable "private_subnets_cidr" {
#  type    = list(string)
  default = "192.168.1.128/26"
}

variable "vpc_cidr" {
#  type    = list(string)
  default = "192.168.1.0/24"
}

variable "key_name" {
  description = "Unique name for the key, should also be a valid filename. This will prefix the public/private key."
  default = "ec2-key-terraform" # in our case!
}

variable "path" {
  description = "Path to a directory where the public and private key will be stored."
  default     = "C:\\Users\\Shobhit Pandey\\Desktop\\SHOBHIT WORK"
}

variable "aws_creds_path" {
  description = "path of aws creds"
  default     = "C:\\Users\\Shobhit Pandey\\.aws\\credentials"
}
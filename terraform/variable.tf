
# VPC variables
variable "region" {
    type = string
    default = "eu-west-1"
}
variable "main_vpc_cidr" {
    type = string
    default = "10.0.0.0/20"
    }
variable "public_subnets" {
    type = list(string)
    default = ["10.0.2.0/24"]
    }
    
variable "private_subnets" {
    type = list(string)
    default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "PRIVATE_KEY_PATH" {
  default = "/home/mpc/ec2-key"
}
variable "PUBLIC_KEY_PATH" {
  default = "../ec2-key.pub"
}
variable "EC2_USER" {
  default = "ec2-user"
}

variable "create_server" {
    description = "whether to create ec2 servers"
    type = bool
    default = true
}

variable "instance_count" {
    description = "whether to create ec2 servers"
    type = string
    default = "3"
}

variable "az" {
    type = list(string)
    default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

# variable "sg_ingress" {


# }

# variable "sg_egress" {


# }
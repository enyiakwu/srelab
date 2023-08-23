
# VPC variables
variable "region" {
    type = string
    default = "eu-west-1"
}
variable "main_vpc_cidr" {
    type = string
    default = "10.0.0.0/24"
    }
variable "public_subnets" {
    type = list(string)
    default = ["10.0.0.128/28"]
    }
variable "private_subnets" {
    type = list(string)
    default = ["10.0.0.192/28", "10.0.0.209/28"]
}

variable "PRIVATE_KEY_PATH" {
  default = "ec2-key"
}
variable "PUBLIC_KEY_PATH" {
  default = "ec2-key.pub"
}
variable "EC2_USER" {
  default = "ubuntu"
}

variable "create_server" {
    type = list(map)
    default = 3
}

variable "az" {
    type = list(string)
    default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "sg_ingress" {


}

variable "sg_egress" {


}
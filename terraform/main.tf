


module "vpc_01" {
  source  = "terraform-aws-modules/vpc/aws//examples/complete"
  version = "5.1.1"
}


# Create the VPC
resource "aws_vpc" "main" {                # Creating VPC here
    cidr_block       = var.main_vpc_cidr     # Defining the CIDR block use 10.0.0.0/24 for demo
    instance_tenancy = "default"

    enable_dns_hostnames = true
    enable_dns_support = true
    

    tags = {
    Name = "Lab VPC"
    }
}


# Create Internet Gateway and attach it to VPC
resource "aws_internet_gateway" "IGW" {    # Creating Internet Gateway
    vpc_id =  aws_vpc.main.id               # vpc_id will be generated after we create VPC

    tags = {
    Name = "Main VPC IGW"
    }
}

# Create a Public Subnets.
resource "aws_subnet" "publicsubnets" {    # Creating Public Subnets
    vpc_id =  aws_vpc.main.id
    cidr_block = "${var.public_subnets}"        # CIDR block of public subnets
}

# Create a Private Subnet                   # Creating Private Subnets
resource "aws_subnet" "privatesubnets" {
    count = 2
    vpc_id =  aws_vpc.main.id
    cidr_block = "${var.private_subnets}"          # CIDR block of private subnets
}

# Route table for Public Subnet
resource "aws_route_table" "PublicRT" {    # Creating RT for Public Subnet
vpc_id =  aws_vpc.main.id
        route {
cidr_block = "0.0.0.0/0"               # Traffic from Public Subnet reaches Internet via Internet Gateway
gateway_id = aws_internet_gateway.IGW.id
    }

    tags = {
    Name = "Public Route Table"
    }
}

# Route table for Private Subnet's
resource "aws_route_table" "PrivateRT" {    # Creating RT for Private Subnet
vpc_id = aws_vpc.main.id
route {
cidr_block = "0.0.0.0/0"             # Traffic from Private Subnet reaches Internet via NAT Gateway
nat_gateway_id = aws_nat_gateway.NATgw.id
}
}

# Route table Association with Public Subnet's
resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.publicsubnets.id
    route_table_id = aws_route_table.PublicRT.id
}

# Route table Association with Private Subnet's
resource "aws_route_table_association" "PrivateRTassociation" {
subnet_id = aws_subnet.privatesubnets.id
route_table_id = aws_route_table.PrivateRT.id
}

# resource "aws_eip" "nateIP" {
#     vpc   = true
# }

# # Creating the NAT Gateway using subnet_id and allocation_id
# resource "aws_nat_gateway" "NATgw" {
#     allocation_id = aws_eip.nateIP.id
#     subnet_id = aws_subnet.publicsubnets.id
# }

resource "aws_eip" "bastion-eip" {
    vpc   = true
}

# Provide a security group for SSH and HTTP for servers

resource "aws_security_group" "ssh_sre" {
vpc_id = aws_vpc.main.id
egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {       # ssh inbound
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
cidr_blocks = ["0.0.0.0/0"] // Ideally best to use your machines' IP. However if it is dynamic you will need to change this in the vpc every so often. 
  }

# ingress {       # http inbound
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
}

resource "aws_key_pair" "ec2-key" {
    key_name   = "ec2-key"
    public_key = file(var.PUBLIC_KEY_PATH) // Path is in the variables file
}



# possible ubuntu amis: eu-west-1 hvm, ebs-ssd, 16.04 LTS ami-0e8225827581c983a ami-0f29c8402f8cce65c

resource "aws_instance" "nginx_server" {
    count = var.create_server ? 3 : 1
    
    ami           = "ami-0e8225827581c983a"
    instance_type = "t2.micro"
    key_name =  aws_key_pair.ec2-key.id
    subnet_id = aws_subnet.privatesubnets[0].id

    for_each = var.create_server
        content {
        tags = {
        Name = "nginx_server_${count.index}"
        }
    # VPC and AZs
        vpc_security_group_ids = ["${aws_security_group.ssh_sre.id}"]
        availability_zone = element(var.azs, "${count.index}")

    # nginx installation
        # storing the nginx.sh file in the EC2 instnace
        provisioner "file" {
            source      = "nginx.sh"
            destination = "/tmp/nginx.sh"
        }
        # Provisioning the EC2 using the nginx.sh file
        # Terraform does not reccomend this method becuase Terraform state file cannot track what the script is provisioning
        provisioner "remote-exec" {
            inline = [
                "chmod +x /tmp/nginx.sh",
                "sudo /tmp/nginx.sh"
                ]
        }
        # Setting up the ssh connection to install the nginx server
        connection {
            type        = "ssh"
            host        = self.public_ip
            user        = "ubuntu"
            private_key = file("${var.PRIVATE_KEY_PATH}")
    }
    }
}

resource "aws_instance" "bastion" {    
    ami           = "ami-0e8225827581c983a"
    instance_type = "t2.micro"
    key_name =  aws_key_pair.ec2-key.id
    subnet_id = aws_subnet.publicsubnets.id
    associate_public_ip_address = false

    vpc_security_group_ids = ["${aws_security_group.ssh_sre.id}"]

    tags = {
        Name = "bastion"
        }

    lifecycle {
      ignore_changes = [ 
        associate_public_ip_address,
       ]
}
}

# Assign bastion to public eip
resource "aws_eip_association" "bastion-eip-association" {
    instance_id = aws_instance.bastion.id
    allocation_id = aws_eip.bastion-eip.id
}

# ELB configuration
# resource "aws_lb" "sre-lb" {
#   name               = "sre-lb-tf"
#   internal           = false
#   load_balancer_type = "network"
#   subnets            = [for subnet in aws_subnet.publicsubnets : subnet.id]

#   # enable_deletion_protection = true

#   tags = {
#     Environment = "test-lb"
#   }
# }
# Create a new load balancer
resource "aws_elb" "sre-lb" {
  name               = "sre-elb-tf"
  availability_zones = var.az

  access_logs {
    bucket        = "foo"
    bucket_prefix = "sre-lb"
    interval      = 600
  }

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

#   listener {
#     instance_port      = 8000
#     instance_protocol  = "http"
#     lb_port            = 443
#     lb_protocol        = "https"
#     ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
#   }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    target              = "HTTP:8000/"
    interval            = 60
  }

  instances                   = [aws_instance.nginx_server[0].id,  aws_instance.nginx_server[1].id,  aws_instance.nginx_server[2].id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "sre-elb-tf"
  }
}


# # attach 3 nginx servers to ELB
# resource "aws_elb_attachment" "sre-elb-attach" {
#     elb = aws_lb.sre-lb.id
#     for_each = aws_instance.nginx_server
#         content {
#             instance = aws_instance.nginx_server[0].id

#         }
# }




















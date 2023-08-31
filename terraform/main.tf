
# Create the VPC
resource "aws_vpc" "main" {                # Creating VPC here
    cidr_block       = var.main_vpc_cidr     # Defining the CIDR block use 10.0.0.0/24 for demo
    instance_tenancy = "default"

    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
    Name = "Lab VPC"
    }

#     lifecycle {
#       ignore_changes = [ 
#         aws_route53_zone_association,
#        ]
# }
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
    cidr_block = element(var.public_subnets, 0)      # CIDR block of public subnets

    tags = {
    Name = "Public Subnet"
    }
}

# Create a Private Subnet                   # Creating Private Subnets
resource "aws_subnet" "privatesubnets" {
    count = 2
    vpc_id =  aws_vpc.main.id
    cidr_block = element(var.private_subnets, count.index)          # CIDR block of private subnets
    availability_zone = element(var.az, count.index)

    tags = {
    Name = "Private Subnet ${count.index}"
    }
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
    subnet_id = aws_subnet.privatesubnets[0].id
    route_table_id = aws_route_table.PrivateRT.id
}

resource "aws_eip" "nateIP" {
    domain = "vpc"
    # vpc   = true
}

# Creating the NAT Gateway using subnet_id and allocation_id
resource "aws_nat_gateway" "NATgw" {
    allocation_id = aws_eip.nateIP.id
    subnet_id = aws_subnet.publicsubnets.id
}

resource "aws_eip" "bastion-eip" {
    domain = "vpc"
    # vpc   = true
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

resource "aws_security_group" "elb" {
    name        = "srelbsg"
    description = "ELB SG"
    vpc_id      = "${aws_vpc.main.id}"
    egress {
        from_port = "443"
        to_port   = "443"
        protocol  = "tcp"
        cidr_blocks = [
            "10.0.0.0/16"
        ]
    }
    tags = {
        Name = "elb"
    }
    depends_on = [
        aws_subnet.privatesubnets
    ]
}

resource "aws_key_pair" "ec2-key" {
    key_name   = "ec2-key"
    public_key = file(var.PUBLIC_KEY_PATH) // Path is in the variables file
}


# possible ec2-user amis: eu-west-1 hvm, ebs-ssd, 18.04 LTS - suitable for t2.micro tier ami-0464e8a4eb8d4fce2

resource "aws_instance" "nginx_server" {
    count = var.create_server ? 3 : 0
    
    ami           = var.server_ami
    instance_type = "t2.micro"
    key_name =  aws_key_pair.ec2-key.id
    subnet_id = aws_subnet.privatesubnets[0].id # element(aws_subnet.privatesubnets[*].id, count.index)

    tags = {
    Name = "nginx_server_${count.index}"
        }
    # VPC and AZs
    vpc_security_group_ids = ["${aws_security_group.ssh_sre.id}"]
    # availability_zone = element(aws_subnet.privatesubnets[*].availability_zone, count.index)

    # nginx installation
    user_data = "${file("../nginx.sh")}" # <<EOF
    # #!/bin/bash
    # # sleep until instance is ready
    # until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
    #   sleep 1
    # done
    # # install nginx in server
    # apt-get update
    # apt-get -y install nginx
    # # make sure nginx is started
    # service nginx start

    # # install python and check
    # apt-get update
    # apt-get install python -y

    # EOF

    # use the below provisioners option if these server have public ips or you make the instance accessible from ssh
    
  #   # ssh connection to install the nginx server
  #   connection {
  #     type        = "ssh"
  #     host        = self.public_ip
  #     user        = "ec2-user"
  #     private_key = file("${var.PRIVATE_KEY_PATH}")
  #     }    
  #   # storing the nginx.sh file in the EC2 instnace
  #   provisioner "file" {
  #     source      = "../nginx.sh"
  #     destination = "/tmp/nginx.sh"
  #     }
  #   # Provisioning the EC2 using the nginx.sh file
  #   # Terraform does not reccomend this method becuase Terraform state file cannot track what the script is provisioning
  #   provisioner "remote-exec" {
  #     inline = [
  #         "chmod +x /tmp/nginx.sh",
  #         "sudo /tmp/nginx.sh"
  #         ]                      
  # }
}

# Assign bastion to public eip
resource "aws_eip_association" "bastion-eip-association" {
    instance_id = aws_instance.bastion.id
    allocation_id = aws_eip.bastion-eip.id
}

resource "aws_instance" "bastion" {    
    ami           = var.server_ami
    instance_type = "t2.micro"
    key_name =  aws_key_pair.ec2-key.id
    subnet_id = aws_subnet.publicsubnets.id
    associate_public_ip_address = true

    vpc_security_group_ids = ["${aws_security_group.ssh_sre.id}"]

    tags = {
        Name = "bastion"
        }

    lifecycle {
      ignore_changes = [ 
        associate_public_ip_address,
       ]
    }
    # connection {
    #   type        = "ssh"
    #   host        = "${self.public_ip}" # aws_eip.bastion-eip.public_ip
    #   user        = "ec2-user"
    #   private_key = file("${var.PRIVATE_KEY_PATH}")
    # }
    # provisioner "remote-exec" {
    #   inline      = [
    #     # "sudo yum install python",
    #     # "apt-get install python -y",
    #     "sudo yum install python37",
    #     "python3 --version"
    #     ]
    #   }
    # Configure the bastion to deploy ansible playbok from local exec
    provisioner "local-exec" {
      command = "sleep 30; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu --private-key ${var.PRIVATE_KEY_PATH} -i '${self.public_ip},' ../install_jenkins_apt.yml"
    }
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

# create S3 bucket for ELB

# resource "aws_s3_bucket" "lblogs" {
#   bucket = try("eakwu-lblogs", null)

#   tags = {
#     Name        = "ELB logs bucket"
#   }
# }


# Create a new load balancer
# resource "aws_elb" "sre-lb" {
#   name                = "sre-elb-tf"
#   subnets             = ["${aws_subnet.publicsubnets.id}", aws_subnet.privatesubnets[0].id, aws_subnet.privatesubnets[1].id ] # aws_subnet.privatesubnets[0].id, aws_subnet.privatesubnets[1].id] # aws_subnet.privatesubnets[0].id
#   # availability_zones  = [for zones in aws_subnet.privatesubnets : zones.availability_zone]
#   security_groups = ["${aws_security_group.elb.id}"]

#   # access_logs {
#   #   bucket        = "eakwu-lblogs"
#   #   bucket_prefix = "sre-lb"
#   #   interval      = 60
#   # }

#   listener {
#     instance_port     = 8000
#     instance_protocol = "http"
#     lb_port           = 80
#     lb_protocol       = "http"
#   }

#   listener {
#     instance_port      = 8888
#     instance_protocol  = "tcp"
#     lb_port            = 443
#     lb_protocol        = "tcp"
#   }

#   health_check {
#     healthy_threshold   = 2
#     unhealthy_threshold = 10
#     timeout             = 5
#     target              = "HTTP:8000/"
#     interval            = 60
#   }

#   instances                   = [aws_instance.nginx_server[0].id,  aws_instance.nginx_server[1].id,  aws_instance.nginx_server[2].id]
#   cross_zone_load_balancing   = true
#   idle_timeout                = 400
#   connection_draining         = true
#   connection_draining_timeout = 400

#   tags = {
#     Name = "sre-elb-tf"
#   }
# }

# Create a new load balancer
resource "aws_lb" "sre-lb" {
  name               = "sre-elb-tf"
  internal           = true
  load_balancer_type = "network"

  subnet_mapping {
    subnet_id            = aws_subnet.privatesubnets[0].id
    private_ipv4_address = "10.0.3.250"
  }

  subnet_mapping {
    subnet_id            = aws_subnet.privatesubnets[1].id
    private_ipv4_address = "10.0.4.250"
  }

  tags = {
    Name = "srelab elb"
  }
}


# Create a private hosted zone
resource "aws_route53_zone" "private" {
  name = "srelab.com"

  vpc {
    vpc_id = aws_vpc.main.id
  }
}


# Route53 with Weighted routing

resource "aws_route53_record" "www-dev" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = 5

  weighted_routing_policy {
    weight = 10
  }

  set_identifier = "dev"
  records        = ["dev.srelab.com"]
}

resource "aws_route53_record" "www-live" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = 5

  weighted_routing_policy {
    weight = 90
  }

  set_identifier = "live"
  records        = ["live.srelab.com"]
}


# create a local inventory file for ansible

# resource "local_file" "ansible_hosts" {
#   content = templatefile("../ansible_hosts.tpl" ,
#     {
#       bastion_hosts = aws_instance.bastion.public_ip,
#       nginx_servers = aws_instance.nginx_server.*.public_ip,
#       ssh_pass = var.PRIVATE_KEY_PATH
#     }
#   )

#   filename = "ansible_hosts"
# }

























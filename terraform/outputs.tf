# VPC
output "vpc_id" {
    description = "The ID of the VPC"
    value = try(aws_vpc.main.id, null)

}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = try(aws_vpc.main.arn, null)
}


# Bastion host and server details
output "bastion_eip" {
  description = "The public IP of the bastion host"
  value = try(aws_eip_association.bastion-eip-association.public_ip, null)
}

# output "elb_dns" {
#   description = "elb endpoint"
#   value = try(aws_lb.sre-lb.dns_name, null)
# }

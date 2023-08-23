# VPC
output "vpc_id" {
    description = "The ID of the VPC"
    value = resource.aws_vpc.main.vpc_id

}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = resource.aws_vpc.vpc_arn
}
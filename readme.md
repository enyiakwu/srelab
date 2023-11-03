This sre lab project is adapted from this git - enjoy
https://github.com/tajawal/code-challenge/blob/master/SRE.md

## Terraform:
### Task 01 :
- Create terraform to setup the following
    - Create a VPC With 1 Public subnets and 2 Private Subnet.
    - Setup 3 Webserver "Nginx" Instances in Different AZ with 1 ELB
    - Setup Jump server "Bastion" host.
    - Route 53 weighted routing, healthcheck with Cloudwatch and SNS ( Email notification )

## Ansible: 
### Task 01 :
 - Setup Anisble playbook to deploy Jenkins Docker on Bastion server which you have created using Terraform
 - Ansible should send a slack message on successfull/unsuccessfull deployment 

## CI && CD:
### Task 01 :
 - Build a small docker container for Jenkins using Dockerfile and Docker Compose with self sign ssl 
 
### Task 02 : 
 - Create an docker image based on ubuntu 16.04 for PHP/NGINX App and add following tools: 
    - PHP 
    - curl , git , vim, ping , pip , python,  
    - SSH / mount an RSA key for ubuntu user. 
    - add www-data user
    - allow www-data to connect via ssh without password

## Monitoring: 
### Task 01 : 
   - Create docker-compose stack for ELK Stack and nginx webserver with some nginx logs. 
   - Create 3 Kibana dashboard must be used to monitor important metrics for PHP / NGINX app.
    
## Scripting: 
### Task 01 : 
Given a CSV file where each row contains the name of a city and its state separated by a
comma, your task is to replace the newlines in the file with semicolons as demonstrated in the
sample.

- Input Format
```
Casablanca, Grand Casablanca.
Dubai, Dubai.
Anchorage, Alaska
Asheville, N.C.
Atlanta, Ga.
Atlantic City, N.J.
```

- Output Format

```
Casablanca, Grand Casablanca.;Dubai, Dubai.;Anchorage, Alaska;Asheville, N.C.;Atlanta, Ga.;Atlantic City,
N.J.
```









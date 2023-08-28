#!/bin/bash
# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done
# install nginx in server
apt-get update
apt-get -y install nginx
# make sure nginx is started
service nginx start

# install python3 nad check
apt-get update
apt-get install python -y
# make sure pip is installed
# apt install python-pip -y
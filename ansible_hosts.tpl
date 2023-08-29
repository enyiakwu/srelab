[bastion_hosts]
%{ for ip, ssh_pass in bastion_hosts ~ }
${ip} ansible_ssh_user=ubuntu ansible_ssh_pass=ssh_pass
%{ endfor ~}


[nginx_servers]
%{ for ip, ssh_pass in nginx_servers ~ }
${ip} ansible_ssh_user=ubuntu ansible_ssh_pass=ssh_pass
%{ endfor ~}


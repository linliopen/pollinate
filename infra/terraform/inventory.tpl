[backend]
${private_ip}

[all:vars]
ansible_ssh_private_key_file = ${pass}
ansible_ssh_user = ${user}
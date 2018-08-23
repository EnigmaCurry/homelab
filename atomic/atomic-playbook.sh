#!/bin/sh

sudo docker run \
       -v /var/lib/homelab:/home/jovyan/homelab \
       -v /etc/homelab:/etc/homelab \
       -v /etc/homelab/ssh:/root/.ssh \
       homelab/jupyter_ansible \
       ansible-playbook -i /etc/homelab/hosts /home/jovyan/homelab/$1


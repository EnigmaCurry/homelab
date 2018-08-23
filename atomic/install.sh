#!/bin/sh

# Finish install that cloud-init started

# cloud-init sets these variables and must exist
if [[ ! -v APP_DOMAIN ]]; then
    echo "APP_DOMAIN is not set"
    exit 1
fi
if [[ ! -v TRAEFIK_HOST ]]; then
    echo "TRAEFIK_HOST is not set"
    exit 1
fi
if [[ ! -v ACME_DOMAINS ]]; then
    echo "ACME_DOMAINS is not set"
    exit 1
fi
if [[ ! -v ACME_EMAIL ]]; then
    echo "ACME_EMAIL is not set"
    exit 1
fi
if [[ ! -v DNS_API_KEY ]]; then
    echo "DNS_API_KEY is not set"
    exit 1
fi
if [[ ! -v HOMELAB_HOME ]]; then
    echo "HOMELAB_HOME is not set"
    exit 1
fi
if [[ ! -v HOMELAB_CONF ]]; then
    echo "HOMELAB_CONF is not set"
    exit 1
fi
if [[ ! -v HOMELAB_USER ]]; then
    echo "HOMELAB_USER is not set"
    exit 1
fi
if [[ ! -v HOMELAB_GIT ]]; then
    echo "HOMELAB_GIT is not set"
    exit 1
fi

# Configure homelab
mkdir -p $HOMELAB_CONF/{group_vars,ssh}
chmod 771 $HOMELAB_CONF

## Create ssh key for ansible to access host
ssh-keygen -N '' -f $HOMELAB_CONF/ssh/id_rsa
ssh-keyscan -H $TRAEFIK_HOST > $HOMELAB_CONF/ssh/known_hosts
cat $HOMELAB_CONF/ssh/id_rsa.pub >> /root/.ssh/authorized_keys
cp -a $HOMELAB_CONF/ssh $HOMELAB_CONF/ssh_user
chown -R $HOMELAB_USER:$HOMELAB_USER $HOMELAB_CONF/ssh_user

## hosts inventory
cat <<EOF > $HOMELAB_CONF/hosts
[traefik]
$TRAEFIK_HOST
[admin]
$TRAEFIK_HOST
EOF
chmod 750 $HOMELAB_CONF/hosts

## traefik group_vars
cat <<EOF > $HOMELAB_CONF/group_vars/traefik.yml
---
homelab_home: "$HOMELAB_HOME"
homelab_conf: "$HOMELAB_CONF"
homelab_user: "$HOMELAB_USER"
app_domain: "$APP_DOMAIN"
traefik_host: "$TRAEFIK_HOST"
acme_domains: "$ACME_DOMAINS"
acme_email: "$ACME_EMAIL"
dns_api_key: "$DNS_API_KEY"
EOF
chmod 750 $HOMELAB_CONF/group_vars/traefik.yml
ln -s $HOMELAB_CONF/group_vars/traefik.yml $HOMELAB_HOME/group_vars/traefik.yml

## Build jupyter_ansible image
cd $HOMELAB_HOME/atomic/jupyter_ansible
docker build -t homelab/jupyter_ansible .

## Run the ansible playbook via the docker image
docker run --rm -v $HOMELAB_CONF:/etc/homelab \
       -v $HOMELAB_HOME:/home/jovyan/homelab \
       -v $HOMELAB_CONF/ssh:/root/.ssh \
       homelab/jupyter_ansible \
       ansible-playbook -i /etc/homelab/hosts /home/jovyan/homelab/site.yml

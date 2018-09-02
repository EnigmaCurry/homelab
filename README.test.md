# Manage a docker swarm on digital ocean

## Create local environment

```
python3 -m venv homelab-env
source homelab-env/bin/activate
curl -L https://github.com/digitalocean/doctl/releases/download/v1.9.0/doctl-1.9.0-linux-amd64.tar.gz | tar xvz -C homelab-env/bin
pip install ansible 
```

## Upload SSH key

```
doctl compute ssh-key create $HOSTNAME --public-key "`cat ~/.ssh/id_rsa.pub`"
```

## Create droplet tags for managers and workers

```
doctl compute tag create homelab-manager
doctl compute tag create homelab-worker
```

## Create manager droplet

```
doctl compute droplet create docker1.app.rymcg.tech --image docker-16-04 --size s-1vcpu-1gb --region nyc1 --tag-names homelab-manager,homelab-worker --enable-private-networking --ssh-keys 43:3e:c4:4f:17:91:5a:f6:96:b5:20:fc:49:08:67:1b
```

## Assign floating ip

```
doctl compute floating-ip-action assign 174.138.127.15 108306172
```

## SSH into droplet

```
doctl compute ssh 108306172
```

## From droplet console, initialize the swarm

```
docker swarm init --advertise-addr 10.136.66.157
```


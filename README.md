# homelab

homelab is an Ansbile-powered management environment for your docker
swarm (mainly on Digital Ocean but this is adaptable), and provides a
consistently reproducible administrative console for the swarm, its
deployment, its configuration, and storing (and distributing) secrets.
It is designed to be disposable, and easily recreated anywhere by git
clone. This way you only run the admin console when *you* need it, and
is not as easily hacked as a service running all the time. Secrets are
encrypted by ansible-vault, and can be pushed to your private git
server to backup your configuration.

homelab can be installed on any machine with Python3:

```
python3 -m venv homelab-env
cd homelab-envB
source bin/activate
pip install homelab
homelab init
# -or-
homelab clone git@private-git-url:homelab_example
```

`homelab init` creates a new homelab instance, by doing the following:
 - Initializes a new git repository
 - Creates example ansible playbook templates in this directory
 - Creates a unique tag name for this instance of homelab, to help
   identify resources it will create.
 - Creates a new encrypted ansible vault for storing secrets
 - Prints out a secure encryption password to the screen, instructing
   the user to save the password to their password manager.
 - Creates a password file. The filename is put in .gitignore
 - Optionally encrypts the password file with a gpg identity, which
   can then be added to the git repo.
   
`homelab clone` checks out an existing homelab configuration, by doing the following:
 - git clone from your private git server
 - Reads configuration, and finds the homelab_id, and other sanity check
 - Decrypts gpg encrypted passphrase to hidden password file included
   in .gitignore
 
Either way, setting up a fully configured homelab environment is done
with just a few commands.
 
## Creating an initial configuration

group_vars/homelab.yml is your main homelab configuration file. It is
encrypted with ansible-vault, and you need a passphrase to view or
edit it. (Since homelab created a password file for you, you won't need
to enter the passphrase). Use this command to edit the file:

```
ansible-vault edit group_vars/homelab.yml
```

[Here are the full ansible-vault
docs](https://docs.ansible.com/ansible/2.4/vault.html#ansible-vault)

homelab.yml will already contain the homelab instance id:

    ---
    homelab_id: homelab_xxxxxxxxxxxx
    
For a digital ocean deployment, you need to enter your API KEY:

    ---
    homelab_id: homelab_xxxxxxxxxxxx
    digital_ocean_api_key: your-generated-digital-ocean-auth-token

Put all your secrets in this file, encrypted, and push it to your
homelab repository.

## Creating droplets

https://gitlab.com/snoopdouglas/dobro

https://gitlab.com/snoopdouglas/ansible-inventory-doctl-tags

## Creating a docker swarm

https://thisendout.com/2016/09/13/deploying-docker-swarm-with-ansible/

https://github.com/nextrevision/ansible-swarm-playbook


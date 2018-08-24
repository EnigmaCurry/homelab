# Homelab

Homelab is an Ansible playbook for a self-hosted network laboratory
with automatic SSL support, provided by
[traefik](https://docs.traefik.io/) and [Let's
Encrypt](https://letsencrypt.org/). Applications are deployed as
docker containers wrapped as systemd services, provided by
[mhutter/ansible-docker-systemd-service](https://github.com/mhutter/ansible-docker-systemd-service).

Homelab is equally suited for firewalled home laboratories, or in the
cloud for public services. It all depends on where you call home.
Follow the directions below according to your environment.

## Installation

### Digital Ocean public cloud deployment

 * Login to your Digital Ocean account, on the Networking tab, add a
   domain name to your account (refered to as *example.com* from here
   on.)

 * Configure your domain registrar to use Digital Ocean DNS
   nameservers (Required for Let's Encrypt DNS challenge):

   * ns1.digitalocean.com
   * ns2.digitalocean.com
   * ns3.digitalocean.com

 * Choose a sub-domain name that homelab will manage. Something like
   *app.example.com*. Homelab will later create by itself
   sub-sub-domains off of this, eg. *blog.app.example.com*,
   *chat.app.example.com*. (Homelab is essentially a collection of
   ansible roles, where each role deploys an app or service with
   a unique FQDN.)

 * Generate a Digital Ocean API key (API tab). Name it the same as the
   hostname of the droplet you'll create. You'll need to provide the
   key for the next section. This will be used for the Let's Encrypt
   DNS challenge response. If you want automatic TLS certificate
   renewal, this API key needs to remain valid and be secured on this
   system.
     
 * Create a new droplet to run homelab:

   * Choose Fedora Atomic. (Not regular Fedora. It's on the "Container
     Distributions" tab in the UI, currently.)
   
   * Choose droplet size ($5/1GB works fine for testing)
   
   * Add your own administrative ssh key to login to the console if
     necessary.
     
   * Choose whatever hostname you want for the server, front end users
     won't see this name. In this example, choose 'atomic', when fully
     qualified that would be *atomic.app.example.com*. This is the
     hostname that you would use to ssh into the droplet.

   * Select additional options:
   
     * Choose Private Networking (not strictly necessary, but if you
       plan to have more than one droplet, you'll want this later.)

     * Choose User Data. This will provide a kickstart to operating
       system setup for our droplet.

     * Copy and paste from
       [atomic/atomic-cloud-config.yml](atomic/atomic-cloud-config.yml)
       into the User Data field. Read the setup instructions
       therein. Edit the Environment variables to suit your
       environment. Paste in the API key you generated above.

   * Click Create! You can watch the log of the kickstart if you open
     the console from the droplet page. The droplet will install
     dependencies and then reboot once.
     
 * Create a Floating IP address (Networking tab), assign it to the new
   droplet just created.

 * Create DNS records (Networking tab) for the Floating IP. You need
   two type A records, both pointing to the Floating IP:

   * app.example.com
   * *.app.example.com

 * The droplet will reboot once, then you should now be able to SSH
   into the root terminal of app.example.com.

       ssh root@app.example.com

 * Post installation tasks are run the first time the machine reboots,
   check the log:
 
       journalctl -f --unit post-install

   Wait for the message "Post Installation tasks Complete"

   Look for lines similar to:

       post-install.sh[736]: PLAY RECAP *********************************************************************
       post-install.sh[736]: atomic.app2.rymcg.tech     : ok=14   changed=10   unreachable=0    failed=0
       post-install.sh[736]: Post Installation tasks Complete.
       post-install.sh[736]: Removed /etc/systemd/system/multi-user.target.wants/post-install.service.
       systemd[1]: Started post-install.service.

 * Examine the logs of the traefik container and ensure that the Let's
   Encrypt DNS Challenge completed successfully, or not:

       journalctl --unit traefik_container

   Look for lines similar to:

       level=debug msg="Building ACME client..."
       level=debug msg="https://acme-v02.api.letsencrypt.org/directory"
       level=info msg=Register...
       level=debug msg="legolog: [INFO] acme: Registering account for letsencrypt@example.com"
       level=debug msg="Using DNS Challenge provider: digitalocean"
       level=debug msg="legolog: [INFO][*.app.example.com] acme: Obtaining bundled SAN certificate"
       level=debug msg="legolog: [INFO][*.app.example.com] AuthURL: https://acme-v02.api.letsencrypt.org/....>
       level=debug msg="legolog: [INFO][app.example.com] acme: Trying to solve DNS-01"
       level=debug msg="legolog: [INFO][app.example.com] Checking DNS record propagation
       level=debug msg="legolog: [INFO][app.example.com] The server validated our request"
       level=debug msg="legolog: [INFO][*.app.example.com] acme: Validations succeeded; requesting certificates"
       level=debug msg="legolog: [INFO][*.app.example.com] Server responded with a certificate."

 * Check the demo app is running, and that SSL is working properly. In
   your browser to go to https://atc.app.example.com

## Administration

To recap, homelab does the following:

 - System services are deployed as docker containers. Each container
   is described in an individual Ansible playbook found in
   /var/lib/homelab/playbooks. The main playbook is in
   /var/lib/homelab/site.yml.

 - Container config files are in /etc/homelab

 - Each docker container is wrapped as a systemd service. The name of
   each systemd service uses the docker container name, and appends
   '_container' to the end. For instance, the traefik docker container
   is called 'traefik', therefore the systemd container name is
   'traefik_container'.

 - Ansible is not installed on the host system. Ansible is run from a
   docker container that has ssh keys to the host system. The host has
   access to a wrapper script that will invoke ansible from this
   container: /var/lib/homelab/atomic/atomic-playbook.sh

## Running a playbook

Once the system is running, ansible can be re-run to deploy any
changes you've made to containers or homelab code.

To run all the playbooks:

    /var/lib/homelab/atomic/atomic-playbook.sh site.yml

To run a single playbook:

    /var/lib/homelab/atomic/atomic-playbook.sh playbooks/traefik.yml

**Note: The playbook argument to atomic-playbook is a _relative_ path
 to /var/lib/homelab, mounted inside the container. Don't specify an
 absolute path for the argument when using the wrapper.**

## Container maintennce

You can check if a container is running using the normal docker functions:

    docker ps -a

However, don't start or stop containers manually, instead use
systemd. If you try to stop a container with just docker commands, the
container will be restarted automatically by systemd.

### Stop a container service

    systemctl stop traefik_container

Note: The systemd container is named 'traefik_container', the docker
container is just called 'traefik'

### Start a container service

    systemctl start traefik_container

### View container status

    systemctl status traefik_container

### Prevent a container from starting on boot:

    systemctl disable traefik_container

### Enable a container to start on boot:

    systemctl enable traefik_container

### View container logs

    systemctl logs traefik_container

This contains historical logs from prior runs as well. If you want to
just see the current logs, use docker:

    docker logs traefik_container


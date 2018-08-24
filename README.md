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

### Private home lab installation

Homelab actually started as something that you would use in your own
dwelling, the home you live at. I wanted to have the same kind of
automation I get for cloud services, inside my home on my own private
network.

Before long, my focus shifted to other things, and I shelved
homelab. I've come back to it now, but I've been focussing on digital
ocean and cloud deployment stuff recently. So homelab is not in a
ready state to be deployed at an actual home right now.

But here's the gist, and if you understand the digital ocean workflow
above, and how my configuration works, you can easily adapt this for a
totally private, home LAN type setup.

 - You still need a real internet domain name.
 - You still need a digital ocean account, but you won't deploy any
   droplets. You need to manage your DNS for Let's Encrypt challenge
   response. Digital Ocean is used here only to update the DNS
   records. If you have another way of doing that, then you don't need
   Digital Ocean.
 - You may be wondering.. Yes, you _can_ use Let's Encrypt
   certificates for private LANs! Now you can protect your internal ip
   ranges with TLS. When you view your gateway router admin page,
   you get a valid SSL certificate acceptable in all browsers.
 - You will use the APP_DOMAIN as your own private LAN subnet,
   eg. app.lan.example.com. I choose app.lan because I want a whole
   subdomain for homelab, just as above. _This does not include LAN
   clients_. Clients need to be on their own subnet. For example,
   laptop1.lan.example.com is your laptop, atomic.app.lan.example.com
   is homelab, which serves *.app.lan.example.com.
 - You will create a docker server, and then install homelab on it,
   configuring it with the hostname atomic.app.lan.example.com. I
   haven't done this step yet, since I switched the install to Fedora
   Atomic. Maybe it just works somehow with Fedora Atomic Workstation,
   but I just haven't tried it yet.
 - Anyway, I'll probably want to administer debian instrastructure at
   home, (Fedora Atomic is still strange to me), so that means that
   the same installation steps that atomic runs from
   [atomic/atomic-cloud-config.yml](atomic/atomic-cloud-config.yml)
   and [atomic/install.sh](atomic/install.sh) need to be translated
   into apt-get and debianisms. You can probably just grok the
   commands and configure it by hand. Eventually I'll write a script.
 - You need to add your domain to Digital Ocean and set it up for DNS,
   but you don't need to create any records, as you will rely on your
   own private DNS server (hosted by homelab) for that.
 - You need to generate an API token for Digital Ocean, the same as
   above, and make sure it's being sent to the environment of the
   traefik container (/etc/homelab/traefik/environment), so that it
   can use it to update DNS when Let's Encrypt ask for it to update the
   challenge response every 3-10 months.
 - Note that the docker server running traefik needs an internet
   connection to talk to Let's Encrypt to keep the TLS certificate
   active. However, intermittent connection is OK. You just need to be
   online every 3 months to update the certificate.
 - You could even deploy homelab to the cloud such to guarantee that
   it had constant uptime and internet connection, but then just grab
   the certificate and copy to another homelab instance running on the
   LAN that doesn't necessarily have internet access at all. Then you
   have no worries that your certificate will expire, and need no
   internet access for your LAN.
 - If you're not well versed in TLS/SSL mechanics, you may be
   wondering how this works. I _don't_ know how it works, but I _do_
   understand it: Your OS/browser has a list of valid Certificate
   Authorities (CA), one of which is Let's Encrypt. It understands how
   to validate certificates, it does this all on its own,
   cryptographically. It can validate certificates offline. It needs
   nothing more than the list of CAs, and to check if the signature of
   the certificate is from a valid CA.
 - Ensure your site.yml includes the dnsmasq role, this will provide a
   DNS server for your private lan. (You configure your DHCP server to
   send the DNS server ip address of your docker host to your clients.)
 - The dnsmasq DNS server resolves everything at *.app.lan.example.com to
   the trafeik container, which proxies for all the other individual
   containers you run, each getting their own subdomain, eg
   service1.app.lan.example.com.
 - Everything going through traefik this way gains SSL support, even
   running on your private LAN!

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


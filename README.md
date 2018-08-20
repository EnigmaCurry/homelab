# Homelab

Homelab is an Ansible playbook for constructing a private network
laboratory with automatic SSL support, provided by
[traefik](https://docs.traefik.io/) and [Let's
Encrypt](https://letsencrypt.org/). Applications are deployed as
docker containers wrapped as systemd services, provided by
[mhutter/ansible-docker-systemd-service](https://github.com/mhutter/ansible-docker-systemd-service).

Homelab is equally suited for firewalled home laboratories, or in the
cloud for public services. It all depends on where you call home.
Follow the directions below according to your environment.

## Digital Ocean public cloud deployment

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

 * Create a new droplet to run docker and traefik:

   * Choose Fedora Atomic. (Not regular Fedora. It's on the "Container
     Distributions" tab in the UI, currently.)
   
   * Choose droplet size ($5/1GB works fine for testing)
   
   * Add your own administrative ssh key (This is 80/20 automation, we
     do need to login to the terminal later for final setup and
     maintainence.)
     
   * Choose whatever hostname you want, front end users won't see this
     name. In this example, choose 'docker', when fully qualified that
     would be *docker.app.example.com*. This will be your droplet host
     to administer.
     
   * Select additional options:
   
     * Choose Private Networking (not strictly necessary, but if you
       plan to have more than one droplet, you'll want this later.)

     * Choose User Data. This will provide a kickstart to operating
       system setup for our droplet.
       
     * Copy and paste from [cloud-config.yml](cloud-config.yml) into the
       User Data field. At this point, you shouldn't need to change
       anything in it, you can leave the example.com domains and
       placeholder api keys in place, as these instructions will
       explain the final setup procedures done by hand, on the host
       terminal (hey, entering secret keys is just easier to do
       securely if they are done manually. 80/20 automation.)

   * Click Create! You can watch the log of the kickstart if you open
     the console from the droplet page. The droplet will install
     dependencies and then reboot once.
     
 * Create a Floating IP address (Networking tab), assign it to the new
   droplet just created.

 * Create DNS records (Networking tab) for the Floating IP. You need
   two type A records, both pointing to the Floating IP:

   * app.example.com
   * *.app.example.com

 * You should now be able to SSH into the root terminal of
   app.example.com.

       ssh root@app.example.com

 * Generate a Digital Ocean API key (API tab). Name it the same as the
   hostname of the droplet. You'll need to provide the key for the
   next section. This will be used for the Let's Encrypt DNS challenge
   response. If you want automatic TLS certificate renewal, this API
   key needs to remain valid and be secured on this system.

 * From the console of the new droplet, edit these files, (templates
   of which came from the cloud-config.yml you pasted before, you're
   just filling in the bits now. 80/20.):

   * /etc/homelab/hosts - This is the ansible inventory file, it lists
     the host roles and the servers that will handle those roles. In
     homelab there is only one host role so far (traefik). The file
     should list the FQDN of the droplet hostname (resolving to the
     Floating IP, eg. docker.app.example.com.)

   * /etc/homelab/group_vars/traefik.yml - This is the configuration
     for the traefik ansible role, **it has some secret information that
     should be handled securely**. The file has been permissioned to
     only be readable by root. Edit the following fields:

     * app_domain: the subdomain for all the traefik hosted containers, eg. "app.example.com"
     * traefik_host: the full domain of the docker host, eg. "docker.app.example.com"
     * acme_domains: the wildcard domain used for certificates, eg. "*.app.example.com"
     * acme_email: the email address used for certificates, eg. "letsencrypt@example.com"
     * digital_ocean_auth: the Digital Ocean API auth token used for Lets Encrypt DNS challenges.

 * From a security perspective, you may want to consider that the API
   Key gives access to your entire Digital Ocean account.

   Keeping copies of the API key on the server is required for
   automatic Let's Encrypt certificate renewels to work. Every few
   months, Let's Encrypt requires refreshing DNS challenge response
   values, which traefik does for you, automatically. It just requires
   the key, so that it can use the DNS update API. Unfortunately,
   there is no fine-grained permissioning for API keys. Regardless,
   it's a secret, and you need to protect it.

   This means that in addition to good system security practices, you
   may want to limit the kinds of docker containers that you allow to
   run on this host. Experimental, or less trusted containers (or
   indeed all other containers) could be run on auxillary droplets
   that the main droplet running (only) traefik proxies for. Those
   auxillary containers would then be isolated from the system with
   access to the key. This is where the Private Networking tick box on
   droplet creation becomes important. This advanced configuration is
   left devised to the reader.

   Homelab also stores the ACME (Let's Encrypt) secrets generated by
   traefik in the traefik_acme docker volume, so I think it makes
   sense to also host the Digital Ocean API key on the same host. That
   way, in a multi-droplet scenario, you are only storing secrets on a
   single machine, with higher security concerns.
   
 * Now that final configuration files are in place, you can invoke the
   ansible playbook to finish the docker container service creation:

       ansible-playbook -i /etc/homelab/hosts /root/homelab/site.yml

 * Each role listed in site.yml is now created as its own systemd
   service, and should now be running.

 * The admin screen of traefik is only visible to the host itself, on
   127.0.0.1. To view it remotely you will need to forward the port
   through SSH when you connect:

       ssh -L 8080:localhost:8080 docker.app.example.com

   The traefik status page should be visible at http://localhost:8080

 * Examine the logs of the traefik container and ensure that the Let's
   Encrypt DNS Challenge completed successfully, or not:

       journalctl --unit traefik_container

   Look for lines similar to:

       level=debug msg="Building ACME client..."
       level=debug msg="https://acme-v02.api.letsencrypt.org/directory"
       level=info msg=Register...
       level=debug msg="legolog: [INFO] acme: Registering account for letsencrypt@example.com>
       level=debug msg="Using DNS Challenge provider: digitalocean"
       level=debug msg="legolog: [INFO][*.app.example.com] acme: Obtaining bundled SAN certificat>
       level=debug msg="legolog: [INFO][*.app.example.com] AuthURL: https://acme-v02.api.letsencr>
       level=debug msg="legolog: [INFO][app.example.com] acme: Trying to solve DNS-01"
       level=debug msg="legolog: [INFO][app.example.com] Checking DNS record propagation using [6>
       level=debug msg="Provider event received {Status:start ID:abcdefghijklmnopqrstuvwxyz123456>

 * Check the demo app is running, and that SSL is working properly. In
   your browser to go to https://atc.app.example.com

## Hypothetical home lab deployment

 * You have a docker server on a private LAN with a domain name of
   ```docker.app.example.com```. You have an SSH key setup to allow
   remote access from Ansible, which also runs on the same LAN. No
   port forwarding from the Internet is required.

 * You own the domain name called ```example.com```. (This must be a
   real internet domain name for Lets Encrypt verification to work.)

 * You have a Digital Ocean account with which you manage the DNS for
   ```example.com```. (This can work with other DNS hosts as well, see
   Configuration.)
 
 * You have added ```example.com``` to the Domain list on the
   Networking tab within your Digital Ocean account.

 * You have setup your Domain Registrar to point ```example.com``` to
   Digital Ocean nameservers:

   * ns1.digitalocean.com
   * ns2.digitalocean.com
   * ns3.digitalocean.com

 * You have chosen ```app.example.com``` to be the domain that will be
   controlled by homelab (app_domain). All containers receive
   subdomains of it like ```blog.app.example.com``` and
   ```thing2.app.example.com```.
   
 * You have created a Digital Ocean API token via the API tab on your
   account, and configured homelab (see Configuration).
   
 * Traefik uses the Digital Ocean API to perform DNS challenge
   authorization with Lets Encrypt. Once traefik starts, it will
   automatically create a wildcard SSL certificate for
   ```*.app.example.com``` and all your containers sitting behind
   traefik will now use it.

 * Digital Ocean is only used for changing the DNS records that Lets
   Encrypt needs. It does not provide any DNS for the local LAN, nor
   for the containers herein. That is the role for the dnsmasq
   container.

 * The dnsmasq service container provides local DNS for the app_domain
   on the LAN. You have used a real internet domain called
   ```app.example.com```, but this subdomain is not configured for the
   Internet. Only within your local network, talking to the dnsmasq
   server, can you resolve the local IP addresses. Dnsmasq resolves
   ```*.app.example.com``` to the Docker host LAN IP address that
   traefik is listening on. Queries for other domain names (anything
   not ending in ```.app.example.com```) are forwarded to the upstream
   DNS servers configured on the docker host (```/etc/resolv.conf```).
   
 * You have configured your router DHCP settings to tell clients to
   use the IP address of the docker host as your primary DNS server
   for your LAN. 
   
   * If your docker host uses this same DHCP server, ensure that you
   configure a static DNS server in the docker host networking
   configuration, otherwise DNS forwarding for non-app domains will
   fail.

 * You now have easy, automatic, verified SSL certificates for service
   containers running on your private LAN!

### Manual Configuration

 * Provision a server running docker with SSH keys installed.
 * Point your domain nameservers to the ones provided by Digital Ocean.
 * Generate an API token on Digital Ocean website.
 * Clone this repository on your ansible controller (maybe your
   laptop, where you have ansible installed, not the docker server):
 
        git clone https://github.com/EnigmaCurry/homelab.git
     
 * Install ansible with your system package manager.
 
 * Install ansible requirements:
 
        ansible-galaxy install -r requirements.yml

 * Create a hosts file (inventory) in this same directory, put in your
   docker host name:
 
         [traefik]
         docker.app.example.com
     
 * Create a new ansible vault for sensitive data, and choose a good
   passphrase to encrypt it:
 
        ansible-vault create group_vars/traefik.yml
     
 * In the editor that opens, save the same information as found in
   [traefik.example.yml](group_vars/traefik.example.yml):
   
   * app_domain: the subdomain for all the traefik hosted containers, eg. "app.example.com"
   * traefik_host: the full domain of the docker host, eg. "docker.app.example.com"
   * acme_domains: the wildcard domain used for certificates, eg. "*.app.example.com"
   * acme_email: the email address used for certificates, eg. "letsencrypt@example.com"
   * digital_ocean_auth: the digital ocean API auth token used for
     Lets Encrypt DNS challenges.

 * If you want to use a different DNS host, you will need to setup a
   token in ```roles/traefik/templates/environment.j2``` and change
   the acme.dnsChallege provider name in
   ```roles/traefik/templates/traefik.toml.j2```. See the [traefik
   docs for more
   information](https://docs.traefik.io/configuration/acme/#provider).

* Run the playbook to deploy, any time you make changes:
 
        ansible-playbook --ask-vault-pass -i hosts site.yml
     
 * Each container is now enabled (and started) as a systemd service on
   the docker host.

 * The traefik admin interface gives you a visual representation of
   the running configuration, showing which app_domain URL maps to
   each running container. For security reasons, this interface is
   only configured to run locally on the docker host, to see it
   remotely you can forward the port through SSH:
   
        ssh -L 8080:localhost:8080 docker.app.example.com
        
   Which, for the duration that you leave this SSH connection open,
   you can see the Traefik admin interface in your browser at
   http://localhost:8080.
   
 * The Traefik interface is read only. You modify the settings by
   modifying
   [traefik.toml.j2](roles/traefik/templates/traefik.toml.j2) and
   rerunning ansible-playbook as above. Per-container configurations
   are made through docker labels, applied to the containers in the
   Ansible roles. Each container role contains the Traefik config for
   which domain name (```whatever.app.example.com```) and HTTP port
   inside the container (usually >1024, for security) should be
   forwarded from the container.

 * Assuming the dnsmasq service is now running, and that you have
   configured your LAN to use it as its primary DNS server, all your
   containers should now respond to individual ```*.app.example.com```
   URLs, on port 80 and 443. Any request to port 80 gets redirected to
   port 443. You should see the green ```https://``` SSL information
   in your browser URL bar, which upon inspection shows the wildcard
   domain certificate issued by Lets Encrypt. As long as traefik stays
   running it will manage the automatic renewal of the certificate
   before it expires.

 * If things did not go as smoothly, check the logs on the server. They
   are found through the Systemd interface. Each container is its own
   unit:
   
        journalctl --unit traefik_container

 * All docker containers are disposable. If a container dies, or is
   removed, it will be recreated and restarted automatically by
   systemd. If a container goes haywire, or does not update, you can
   just remove it:
   
        docker rm -f traefik_container
        
    And systemd will recreate it, restarted again.
    
 * If you want to shut a container down, use the systemd way:
 
        systemctl stop traefik_container

 * You can remove a container entirely:
 
        systemctl disable traefik_container
        
   And the next time you run ansible-playbook, the container (and
   systemd service) will reappear, reenabled.


## Services implemented

 * traefik - Reverse SSL HTTP proxy with Lets Encrypt Certificate. All
   the containers that provide an HTTP interface, are proxied through
   traefik and thereby gain automatic SSL support.

 * dnsmasq - LAN local DNS service. Configured to provide wildcard DNS
   for a whole domain as well as general DNS forwarding to an upstream
   DNS server (whichever one is already configured on the docker
   host, probably your router.)

 * jupyter-notebook - A single user IPython Notebook server. The
   'work' directory is saved to a docker volume called
   jupyter_notebooks.
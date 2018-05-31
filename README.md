# Homelab

homelab is an Ansible playbook for constructing a private home network
laboratory with automatic SSL support. Applications are deployed as
docker containers wrapped as systemd services.

## Hypothetical deployment

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

## Services implemented

 * dnsmasq - LAN local DNS service. Configured to provide wildcard DNS
   for a whole domain as well as general DNS forwarding to an upstream
   DNS server (whichever one is already configured on the docker
   host, probably your router.)
 * traefik - Reverse SSL HTTP proxy with Lets Encrypt Certificate. All
   the containers that provide an HTTP interface, are proxied through
   traefik and thereby gain automatic SSL support.

## Configuration

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


# Only run if minion is Ubuntu, otherwise don't run and just display an error!
# HOSTNAME MUST BE SET TO A VALID DOMAIN FOR THIS STATE TO WORK! (hostnamectl set-hostname)
# This Salt state should be run on a clean-installed server.
{% if grains['os'] == 'Ubuntu' %}
################################# INITIAL SERVER SETUP #################################
# Add some network optimization rules to sysctl.d
/etc/sysctl.conf:
  file.append:
    - source: salt://vpnserver/sysctl.conf
# Update sysctl
sysctl -p:
  cmd.run
################################# LET'S ENCRYPT #################################
# Install software-properties-common
software-properties-common:
  pkg.installed
# Add Certbot PPA
certbot-repo:
  pkgrepo.managed:
    - ppa: certbot/certbot
# Install certbot from repo
certbot:
  pkg.latest:
    - require:
      - certbot-repo
# Add cronjob to renew LE certificates
certbot renew -n:
  cron.present:
    - identifier: CERTBOTRENEW
    - minute: 0
    - hour: 0
    - daymonth: 1
# Get a Let's Encrypt certificate for the FQDN
fetch-letsencrypt-certificate:
  cmd.run:
    - name: certbot certonly --standalone --domain {{ grains['nodename'] }} -m admin@unixfy.me --agree-tos --no-eff-email -n
################################# V2RAY #################################
# Install v2ray
{% if salt['grains.get']('vpnserver-v2ray-installed') != true %}
get-v2ray-script:
  cmd.run:
    - name: umask 022; wget https://install.direct/go.sh -O /root/v2ray-install.sh
    - creates: /root/v2ray-install.sh
run-v2ray-script:
  cmd.run:
    - name: bash /root/v2ray-install.sh
  grains.present:
    - name: vpnserver-v2ray-installed
    - value: True
{% endif %}
# Generate server config based on template
# We need to use Jinja templates in order to grab the ID / hostname / etc from Grains and Pillar.
/etc/v2ray/config.json:
  file.managed:
    - source: salt://vpnserver/v2ray-server.json
    - template: jinja
# Generate client config based on template
/root/v2ray-client.json:
  file.managed:
    - source: salt://vpnserver/clients/v2ray.json
    - template: jinja
# Monitor v2ray service and restart if config.json is edited
v2ray:
  service.running:
    - enable: True
    - watch:
        - file: /etc/v2ray/config.json
################################# WIREGUARD #################################
{% if salt['grains.get']('vpnserver-wg-installed') != true %}
# Wget the Wireguard script
get-wireguard-script:
  cmd.run:
    - name: umask 022; wget https://raw.githubusercontent.com/l-n-s/wireguard-install/master/wireguard-install.sh -O /root/wireguard-install.sh
    - creates: /root/wireguard-install.sh
# Run the Wireguard script
run-wireguard-script:
  cmd.run:
    - name: bash /root/wireguard-install.sh
    - env:
      - INTERACTIVE: 'no'
      - CLIENT_DNS: '9.9.9.9,1.1.1.1,1.0.0.1'
      - SERVER_PORT: '51820'
      - SERVER_HOST: {{ grains['external_ip'] }}
      - CLIENT_NAME: {{ grains['machine_id'] }}
  grains.present:
    - name: vpnserver-wg-installed
    - value: True
{% endif %}
# Monitor the wg-quick service
wg-quick@wg0:
  service.running:
    - enable: True
################################# OPENVPN #################################
{% if salt['grains.get']('vpnserver-ovpn-installed') != true %}
# Wget the OpenVPN script
get-openvpn-script:
  cmd.run:
    - name: umask 022; wget https://raw.githubusercontent.com/Angristan/openvpn-install/master/openvpn-install.sh -O /root/openvpn-install.sh
    - creates: /root/openvpn-install.sh
# Run the OpenVPN script
run-openvpn-script:
   cmd.run:
     - name: bash /root/openvpn-install.sh
     - env:
       - AUTO_INSTALL: 'y'
       - APPROVE_INSTALL: 'y'
       - ENDPOINT: {{ grains['external_ip'] }}
       - PORT_CHOICE: '1'
       - PROTOCOL_CHOICE: '2'
       - DNS: '3'
       - CLIENT: {{ grains['machine_id'] }}
   grains.present:
     - name: vpnserver-ovpn-installed
     - value: True
{% endif %}
# Monitor the OpenVPN service and restart if server.conf is modified
openvpn:
  service.running:
    - enable: True
################################# SSH TUNNEL #################################
# Create SSH tunneling user and prevent login (nologin shell)
tunnel:
  user.present:
    - shell: /sbin/nologin
    - createhome: True
    - home: /home/tunnel
    - empty_password: True
# Create the .ssh directory in tunnel's home directory
/home/tunnel/.ssh:
  file.directory:
    - user: tunnel
    - group: tunnel
    - mode: 700
# Generate authorized_keys file based on Pillar data
/home/tunnel/.ssh/authorized_keys:
  file.managed:
    - mode: 600
    - user: tunnel
    - group: tunnel
    - template: jinja
    - source: salt://vpnserver/tunnel_keys
# Todo: may need to use files.append to implement sshd security for tunnel user
################################# SSLH #################################
# Install sslh
sslh_pkg:
  pkg.latest:
    - name: sslh
    - install_recommends: False
# Configure sslh based on template
/etc/default/sslh:
  file.managed:
    - source: salt://vpnserver/sslh
    - template: jinja
# Monitor sslh service and restart if sslh is updated OR config file is changed
sslh:
  service.running:
    - enable: True
    - watch:
      - pkg: sslh
      - file: /etc/default/sslh
################################# EXPORT CLIENT CONFIGS #################################
{% if salt['grains.get']('vpnserver-configs-uploaded') != true %}
# Create a tar archive of all generated config files
zip-up-configs:
  cmd.run:
    - name: tar -cvf /root/{{ grains['host'] }}.tar /root/*.ovpn /*.conf /root/*.json
# Upload all config files to https://share.unixfy.me, expire the archive in 2 hours, and generate a json response
upload-configs:
  cmd.run:
    - name: 'curl -H "Linx-Randomize: yes" -H "Linx-Expiry: 1200" -H "Accept: application/json" -T {{ grains['host'] }}.tar https://share.unixfy.me/upload/ > cfgupload.log'
  grains.present:
    - name: vpnserver-configs-uploaded
    - value: True
    - require:
      - zip-up-configs
{% endif %}
{% else %}
echo "OS Not Compatible! Only Ubuntu works with this Salt state at this time.":
  cmd.run
{% endif %}

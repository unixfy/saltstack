# Only run if minion is Ubuntu, otherwise don't run and just display an error!
# HOSTNAME MUST BE SET TO FQDN FOR THIS STATE TO WORK!
{% if grains['os'] == 'Ubuntu' %}
################################# INITIAL SERVER SETUP #################################
# Add some network optimization rules to sysctl.d
/etc/sysctl.d/10-vpnserver.conf:
  file.managed:
    - source: salt://vpnserver/sysctl.conf
# Update sysctl
sysctl -p:
  cmd.run
################################# LET'S ENCRYPT #################################
software-properties-common:
  pkg.installed
certbot:
  pkg.latest
    - fromrepo: ppa:certbot/certbot
certbot renew -n:
  cron.present:
    - identifier: CERTBOTRENEW
    - minute: 0
    - hour: 0
    - daymonth: 1
certbot certonly --standalone --domain {{ grains['fqdn'] }} -m admin@unixfy.me --agree-tos --no-eff-email -n
  cmd.run
################################# V2RAY #################################
bash <(curl -L -s https://install.direct/go.sh):
  cmd.run: 
    - hide_output: True
# We need to use Jinja templates in order to grab the ID / hostname / etc from Grains and Pillar.
/etc/v2ray/config.json:
  file.managed:
    - source: salt://vpnserver/v2ray-server.json
    - template: jinja
v2ray:
  service.running:
    - enable: True
################################# WIREGUARD #################################
WIP!

################################# OPENVPN #################################
/root/openvpn-install.sh:
  file.managed:
    user: root
    mode: 755
    source: salt://vpnserver/openvpn-install.sh
bash /root/openvpn-install.sh:
   cmd.run:
     - env:
       - AUTO_INSTALL: 'y'
       - APPROVE_INSTALL: 'y'
       - ENDPOINT: '$(curl -4 ifconfig.co)'
       - PORT_CHOICE: '1'
       - PROTOCOL_CHOICE: '2'
       - DNS: '3'
       - CLIENT: {{ grains['fqdn'] }}

# wip: need to copy client cfg files to share endpoint / scp / etc

################################# SSH TUNNEL #################################
WIP!

################################# SSLH #################################
WIP!

# {{ grains['fqdn'] }}
# lookup grains.list for grain for public ip address

{% else %}
echo "OS Not Compatible! Only Ubuntu works with this Salt state at this time.":
  cmd.run
{% endif %}


base:
  'roles:vpnserver':
     - match: grain
     - vpnserver
  'os_family:Debian':
     - match: grain 
     - ssh
     - unattended-upgrades-deb


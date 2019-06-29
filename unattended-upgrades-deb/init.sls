unattended-upgrades: 
  pkg.installed
/etc/apt/apt.conf.d/50unattended-upgrades:
  file.managed:
    - source: salt://unattended-upgrades-deb/50unattended-upgrades

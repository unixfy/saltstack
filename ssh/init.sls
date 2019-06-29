ssh:
  pkg.installed
/etc/ssh/sshd_config:
  file.managed: 
    - source: salt://ssh/sshd_config
    - user: root
    - group: root

ssh:
  pkg.installed: []
  service.running:
    - require:
      - pkg: ssh
/etc/ssh/sshd_config:
  file.managed: 
    - source: salt://ssh/sshd_config
    - user: root
    - group: root

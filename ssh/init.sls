ssh:
  pkg.installed:
    - name: openssh-server
  service.running:
    - watch:
      - pkg: openssh-server
      - file: /etc/ssh/sshd_config
/etc/ssh/sshd_config:
  file.managed: 
    - source: salt://ssh/sshd_config
    - user: root
    - group: root
/etc/issue.net:
  file.managed:
    - source: salt://ssh/banner

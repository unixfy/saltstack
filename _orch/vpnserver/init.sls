# Orchestration runner for vpnserver/init.sls
# To run: salt-run state.orchestrate _orch/vpnserver
vpn_server:
  salt.state:
    - tgt: 'role:vpnserver'
    - tgt_type: grain
    - sls: vpnserver

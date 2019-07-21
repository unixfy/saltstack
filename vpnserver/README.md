# vpnserver Salt State

This State is designed to automate my VPN server guide, which can be found [here](https://docs.unixfy.me/books/tutorials/page/set-up-vpn-to-bypass-censorship-%28server%29). It rapidly installs all of the features described in the guide.

You should expect that running the state on each minion will take approximately 10 minutes to 2 hours depending on CPU.

This state is designed to be run using `state.highstate` (in conjunction with the top.sls file) or using the orchestration runner, on a master that uses this repository with `gitfs`.

### Setup for VPN server minions

1. Ensure the minion is using Ubuntu 18.04 or 16.04. These two versions are tested and working. Debian might work. RHEL distros won't work. Ensure the minion has a stable connection to the master.

2. Set the hostname using `hostnamectl set-hostname` and point an A record for the hostname - this state will fail if you skip this step!

3. Install Saltstack and join to the master.

4. Add `roles: vpnserver` to `/etc/salt/grains` to ensure correct matching.

5. Join the minion to the master by modifying `master:` in `/etc/salt/minion`. Restart `salt-minion` service.

6. Run one of the commands below on the master.


### Commands for reference:

Run state manually on all minions:

```
salt '*' state.apply vpnserver
```

Use top.sls to match servers with grain roles:vpnserver:

```
salt '*' state.apply
```

Using the orchestration runner to run this State on many minions at once:

```
salt-run state.orchestrate _orch/vpnserver
```

### Adding Wireguard / OpenVPN clients

All of the protocols except for Wireguard and OpenVPN allow unlimited connections per config file. To add a client for Wireguard and OpenVPN, run the commands `salt 'nameofmachine' vpnserver.add-client-wg` or `salt 'nameofmachine' vpnserver.add-client-ovpn` respectively. These States will automatically generate an additional config file and upload it to https://share.unixfy.me for easy retreival.

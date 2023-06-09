```
             _ _                           _       _         _   
 _ _ ___ _ _| | |_ ___ ___ ___ ___ ___ ___| |_ ___| |_   ___| |_ 
| | | .'| | | |  _|___|_ -|   | .'| . |_ -|   | . |  _|_|_ -|   |
 \_/|__,|___|_|_|     |___|_|_|__,|  _|___|_|_|___|_| |_|___|_|_|
                                  |_|                            

Tool used to easily download self-hosted HashiCorp Vault
  snapshot which can be automated with a simple cronjob

Requirements: curl, jq

Vault cluster should be unsealed and on standby.

Configuration for vault-snapshot.sh is set with:
  /path/to/vault-snapshot.sh/config/vault-snapshot.cfg

You must have a token generated with storage/raft READ permissions.
  The token must be placed in /config/vault_token file.
  (Location can be modified in /config/vault-snapshot.cfg)

Usage:
  vault-snapshot.sh [<arguments>]
  vault-snapshot.sh -h | Help - Show this screen.
  vault-snapshot.sh -v | Verbose - Show [info] level output (Default is error only)
  vault-snapshot.sh -c | Check - Only check which Vault node is the master
  vault-snapshot.sh -g | Get - Only get vault snapshot without checking for master node.
                         NOT RECOMMENDED!
Examples:
  vault-snapshot.sh       | Tool fully ran, silent output unless error.
  vault-snapshot.sh -vc   | Verbose output while only checking for master node.
  vault-snapshot.sh -c    | Only master node checked, silent output unless error
  vault-snapshot.sh -vg   | Verbose output while only getting Vault snapshot.
                            NOT RECOMMENDED!
                            
```


<p align="center" width="100%">
<img src="https://img.shields.io/github/license/Sidicer/vault-snapshot.sh?style=flat-square"> <img src="https://img.shields.io/github/v/tag/Sidicer/vault-snapshot.sh?label=version&style=flat-square">
</p>

## Usage

1. Install prerequisites
```sh
# Ubuntu/Debian
sudo apt install git curl jq
# CentOS/RHEL
sudo yum install epel-release -y # needed to install JQ package
sudo yum -y install git curl jq
# Fedora
sudo dnf -y install git curl jq
```
2. Clone and navigate to this repository:
```sh
git clone https://github.com/Sidicer/vault-snapshot.sh.git
cd vault-snapshot.sh
```
3. Add your Vault token (with /storage/ READ permissions):
```sh
echo "hcv.your-token" > config/vault_token
```
4. Configure `_VAULT_URL`:
```sh
vim config/vault-snapshot.cfg
# Change _VAULT_URL= to match your cluster setup
# :wq
```
5. Test `vault-snapshot.sh`:
```sh
bin/vault-snapshot.sh -v
```
6. Automate snapshot creation (weekly):
```sh
crontab -l | { cat; echo "0 5 * * 7 /path/to/vault-snapshot.sh/bin/vault-snapshot.sh"; } | crontab -
```

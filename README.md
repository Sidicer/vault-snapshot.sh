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

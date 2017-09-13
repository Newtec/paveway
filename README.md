# paveway
If you work in an environment where machines often get reinstalled, replaced or added, but usually use the same passwords, paveway can make logging in on them a lot easier. It attempts to log in on a remote machine using a set of passwords you can define, and copies over your ssh public key after it successfully logs in.

## Security
Paveway _clears_ the known SSH host key for a host every time it accesses that host. This avoids the pesky job of manually clearing an old host key and accepting the new one, but it's obviously insecure. This behaviour can be disabled in the configuration file.

## .pavewayrc
Paveway requires a configuration file containing the passwords it should try to use. This repository contains a sample for this file.

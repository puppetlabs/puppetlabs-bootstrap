## Release [0.2.0]
### Summary
This makes the module PDK-compliant for easier maintenance. It also includes a roll up of maintenance changes.

### Added
- PDK conversion [MODULES-6468](https://tickets.puppetlabs.com/browse/MODULES-6468).

### Fixed
- Update bolt usage typo in README [MODULES-5945](https://tickets.puppetlabs.com/browse/MODULES-5945).

## Release 0.1.1
Fix bash script.

## Fixes
- Remove Function keyword from bash script.

## Release 0.1.0
This is the initial release of the bootstrap task.

## Features
- Bootstrap a node with puppet-agent, pointing it at a master.
- Check the CA certificate of the master.
- Set the DNS alt names for the agent.
- Set the certname with which the node should be bootstrapped.

[0.2.0]: https://github.com/puppetlabs/puppetlabs-resource/compare/0.1.1...0.2.0

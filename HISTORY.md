## 0.3.0
### Summary
This release removes the default eponymous task `bootstrap` and separates it into a bourne-shell `bootstrap::linux` task and a powershell `bootstrap::windows` task. It also includes a few new task parameters.

### Changed
- `bootstrap` init task removed to be separated into windows & linux tasks.

### Added
- `bootstrap::windows` task in powershell
- `bootstrap::linux` task in sh
- Task parameter `custom_attribute` for puppet.conf and csr\_attributes.yaml
- Task parameter `extension_request` for puppet.conf and csr\_attributes.yaml

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

[0.3.0]: https://github.com/puppetlabs/puppetlabs-resource/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/puppetlabs/puppetlabs-resource/compare/0.1.1...0.2.0

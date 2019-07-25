# Change log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v1.0.0](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/v1.0.0) (2019-07-25)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/0.5.0...v1.0.0)

### Changed

- pdksync - \(MODULES-8444\) - Raise lower Puppet bound [\#78](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/78) ([david22swan](https://github.com/david22swan))

### Added

- \(FM-8216\) Switch testing to use Litmus [\#94](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/94) ([eimlav](https://github.com/eimlav))
- \(FM-8150\) Add Windows Server 2019 support [\#92](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/92) ([eimlav](https://github.com/eimlav))
- \(FM-8038\) Add RedHat 8 support [\#87](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/87) ([eimlav](https://github.com/eimlav))
- \[FM-7942\] Puppet Strings [\#86](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/86) ([carabasdaniel](https://github.com/carabasdaniel))

### Fixed

- \(FM-8112\) Ensure TLS 1.2 in Windows Task  [\#90](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/90) ([michaeltlombardi](https://github.com/michaeltlombardi))
- \(FM-7919\) Ensure TLSv1.2 is used when temporarily disabling ssl [\#84](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/84) ([steveax](https://github.com/steveax))

## [0.5.0](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/0.5.0) (2019-04-04)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/0.4.1...0.5.0)

### Added

- \(SEN-787\) Make linux and windows private [\#73](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/73) ([conormurraypuppet](https://github.com/conormurraypuppet))
- \(SEN-787\) Add discovery extension metadata [\#72](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/72) ([conormurraypuppet](https://github.com/conormurraypuppet))
- \(SEN-787\) Add implementation metadata [\#71](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/71) ([conormurraypuppet](https://github.com/conormurraypuppet))
- \(MODULES-6989\) Multiple extension\_requests/custom\_attributes Linux task [\#61](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/61) ([eimlav](https://github.com/eimlav))

### Fixed

- Ensure certnames are \*always\* lowercase [\#67](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/67) ([dylanratcliffe](https://github.com/dylanratcliffe))
- pdksync - \(FM-7655\) Fix rubygems-update for ruby \< 2.3 [\#56](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/56) ([tphoney](https://github.com/tphoney))

## [0.4.1](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/0.4.1) (2018-11-05)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/0.4.0...0.4.1)

### Fixed

- \(MODULES-8154\) Correct environment argument [\#49](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/49) ([MikaelSmith](https://github.com/MikaelSmith))

## [0.4.0](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/0.4.0) (2018-09-27)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/0.3.0...0.4.0)

### Added

- pdksync - \(FM-7392\) - Puppet 6 Testing Changes [\#46](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/46) ([pmcmaw](https://github.com/pmcmaw))
- pdksync - \(MODULES-6805\) metadata.json shows support for puppet 6 [\#44](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/44) ([tphoney](https://github.com/tphoney))
- \(MODULES-7511\) Add Environment option for Windows [\#35](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/35) ([MikaelSmith](https://github.com/MikaelSmith))
- \(FM-7269\) - Addition of support for ubuntu 1804 [\#34](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/34) ([david22swan](https://github.com/david22swan))
- \(MODULES-7511\) - Add ability to insert environment name during agent install [\#33](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/33) ([raj-andy1](https://github.com/raj-andy1))
- \[FM-7063\] Addition of Debian 9 support to Bootstrap [\#30](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/30) ([david22swan](https://github.com/david22swan))

### Fixed

- \(MODULES-7838\) Windows task contains typo which causes failure. [\#45](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/45) ([davejohnston](https://github.com/davejohnston))

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


\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*

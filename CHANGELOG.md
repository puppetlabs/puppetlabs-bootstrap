<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v3.0.0](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/v3.0.0) - 2025-01-29

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/v2.1.0...v3.0.0)

### Changed

- pdksync - Remove Puppet 5 from testing and bump minimal version to 6.0.0 [#159](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/159) ([carabasdaniel](https://github.com/carabasdaniel))

### Added

- Added the ability to set puppet.conf settings via a parameter. [#167](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/167) ([benjamin-robertson](https://github.com/benjamin-robertson))
- pdksync - (IAC-973) - Update travis/appveyor to run on new default branch main [#147](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/147) ([david22swan](https://github.com/david22swan))
- add set_noop parameter [#139](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/139) ([zoojar](https://github.com/zoojar))

## [v2.1.0](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/v2.1.0) - 2020-02-07

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/v2.0.0...v2.1.0)

### Added

- (MODULES-10242) Re-Add Ubuntu 14 as supported OS [#119](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/119) ([sheenaajay](https://github.com/sheenaajay))
- (FM-8686) - Addition of Support for CentOS 8 [#117](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/117) ([david22swan](https://github.com/david22swan))

## [v2.0.0](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/v2.0.0) - 2019-11-11

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/v1.0.0...v2.0.0)

### Changed

- pdksync - FM-8499 - remove ubuntu14 support [#114](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/114) ([lionce](https://github.com/lionce))

### Fixed

- (MAINT) Ensure TLS is enabled first on Windows [#106](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/106) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [v1.0.0](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/v1.0.0) - 2019-07-25

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/0.5.0...v1.0.0)

### Changed

- pdksync - (MODULES-8444) - Raise lower Puppet bound [#78](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/78) ([david22swan](https://github.com/david22swan))

### Added

- (FM-8216) Switch testing to use Litmus [#94](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/94) ([eimlav](https://github.com/eimlav))
- (FM-8150) Add Windows Server 2019 support [#92](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/92) ([eimlav](https://github.com/eimlav))
- (FM-8038) Add RedHat 8 support [#87](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/87) ([eimlav](https://github.com/eimlav))
- [FM-7942] Puppet Strings [#86](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/86) ([carabasdaniel](https://github.com/carabasdaniel))

### Fixed

- (FM-8112) Ensure TLS 1.2 in Windows Task  [#90](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/90) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (FM-7919) Ensure TLSv1.2 is used when temporarily disabling ssl [#84](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/84) ([steveax](https://github.com/steveax))

## [0.5.0](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/0.5.0) - 2019-04-04

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/0.4.1...0.5.0)

### Added

- (SEN-787) Make linux and windows private [#73](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/73) ([conormurray95](https://github.com/conormurray95))
- (SEN-787) Add discovery extension metadata [#72](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/72) ([conormurray95](https://github.com/conormurray95))
- (SEN-787) Add implementation metadata [#71](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/71) ([conormurray95](https://github.com/conormurray95))
- (MODULES-6989) Multiple extension_requests/custom_attributes Linux task [#61](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/61) ([eimlav](https://github.com/eimlav))

### Fixed

- Ensure certnames are *always* lowercase [#67](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/67) ([dylanratcliffe](https://github.com/dylanratcliffe))
- pdksync - (FM-7655) Fix rubygems-update for ruby < 2.3 [#56](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/56) ([tphoney](https://github.com/tphoney))

## [0.4.1](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/0.4.1) - 2018-11-07

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/0.4.0...0.4.1)

### Fixed

- (MODULES-8154) Correct environment argument [#49](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/49) ([MikaelSmith](https://github.com/MikaelSmith))

## [0.4.0](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/0.4.0) - 2018-09-27

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/0.3.0...0.4.0)

### Added

- pdksync - (FM-7392) - Puppet 6 Testing Changes [#46](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/46) ([pmcmaw](https://github.com/pmcmaw))
- pdksync - (MODULES-6805) metadata.json shows support for puppet 6 [#44](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/44) ([tphoney](https://github.com/tphoney))
- (MODULES-7511) Add Environment option for Windows [#35](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/35) ([MikaelSmith](https://github.com/MikaelSmith))
- (FM-7269) - Addition of support for ubuntu 1804 [#34](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/34) ([david22swan](https://github.com/david22swan))
- (MODULES-7511) - Add ability to insert environment name during agent install [#33](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/33) ([raj-andy1](https://github.com/raj-andy1))
- [FM-7063] Addition of Debian 9 support to Bootstrap [#30](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/30) ([david22swan](https://github.com/david22swan))

### Fixed

- (MODULES-7838) Windows task contains typo which causes failure. [#45](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/45) ([davejohnston](https://github.com/davejohnston))

## [0.3.0](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/0.3.0) - 2018-06-04

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/0.2.0...0.3.0)

### Added

- (MODULES-6831) Add Windows support  [#18](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/18) ([Iristyle](https://github.com/Iristyle))
- (feature) add extension_request custom_attribute [#17](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/17) ([tphoney](https://github.com/tphoney))

### Fixed

- (FM-6926) Better checks when running install.bash [#22](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/22) ([tphoney](https://github.com/tphoney))

## [0.2.0](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/0.2.0) - 2018-03-09

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/0.1.1...0.2.0)

## [0.1.1](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/0.1.1) - 2017-10-11

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/0.1.0...0.1.1)

### Other

- release prep 0.1.1 and fix bash script [#10](https://github.com/puppetlabs/puppetlabs-bootstrap/pull/10) ([tphoney](https://github.com/tphoney))

## [0.1.0](https://github.com/puppetlabs/puppetlabs-bootstrap/tree/0.1.0) - 2017-10-11

[Full Changelog](https://github.com/puppetlabs/puppetlabs-bootstrap/compare/e3474bc145d2d4e32832a3518ef4e92bfaa317a4...0.1.0)

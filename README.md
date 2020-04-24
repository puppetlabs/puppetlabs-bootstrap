
# bootstrap

#### Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the task is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)
1. [Getting help - Some Helpful commands](#getting-help)

## Description

This module provides the bootstrap task. This allows you to install Puppet agents on un-puppeted hosts via the ssh or winrm transports.

## Requirements

This module requires both the `bolt` gem on the machine from which you are running bolt commands (the controller node), and a Puppet Enterprise 2017.3 or later master hosting agent repositories.

Linux machines receiving task requests must have bash for now.  Windows machines must have PowerShell. (See [Limitations](#limitations) for more info.)

## Usage

To run the bootstrap task, use the bolt command, specifying the PE master from which the Puppet agent package should be installed and to which the agent should submit its certificate for signing.

#### Example: Basic usage

On the command line:
* For Linux,   run `bolt task run bootstrap::linux   master=<master's fqdn> --nodes x,y,z --modulepath /path/to/modules`
* For Windows, run `bolt task run bootstrap::windows master=<master's fqdn> --nodes x,y,z --modulepath /path/to/modules`
For all advanced examples below, simply replace `bootstrap::linux` by `bootstrap::windows` to perform the action on Windows.

#### Example: Verify the master's CA on initial connection

Optionally to validate the connection during the bootstrap process, specify the puppet master's CA cert by adding the cacert_content option:
`bolt task run bootstrap::linux master=<master's fqdn> cacert_content="$(cat /etc/puppetlabs/puppet/ssl/certs/ca.pem)" --nodes x,y,z --modulepath /path/to/modules`

#### Example: Specify a custom certname

Optionally to install the Puppet agent with a certname other than the fqdn of the target node, specify the custom certname:
`bolt task run bootstrap::linux master=<master's fqdn> certname=<custom certname> --nodes x,y,z --modulepath /path/to/modules`

#### Example: Specify the environment

Optionally to install the puppet-agent with a specific environment other than the default environment `production`, specify the custom environment:
`bolt task run bootstrap::linux master=<master's fqdn> environment=<custom environment> --nodes x,y,z --modulepath /path/to/modules`

#### Example: Specify noop

Optionally to install the puppet-agent with noop:
`bolt task run bootstrap::linux master=<master's fqdn> set_noop=true--nodes x,y,z --modulepath /path/to/modules`

#### Example: Specify custom dns alt names

Optionally to install the Puppet agent with custom dns alt names, specify the custom dns alt names:
`bolt task run bootstrap::linux master=<master's fqdn> dns_alt_names=<comma-separated list of alt names for the node> --nodes x,y,z --modulepath /path/to/modules`
(see [Compile master installation](https://docs.puppet.com/pe/latest/install_multimaster.html) documentation for more info).

You can also run tasks in the PE console. See PE task documentation for complete information.

#### Example: Specify a custom_attribute

Optionally to install the Puppet agent and adding a setting to puppet.conf and including it in the custom_attributes section of csr_attributes.yaml: `bolt task run bootstrap master=<master's fqdn> custom_attribute=key=value --nodes x,y,z --modulepath /path/to/modules`

#### Example: Specify a extension_request

Optionally to install the Puppet agent and adding a setting to puppet.conf and including it in the extension_requests section of csr_attributes.yaml: `bolt task run bootstrap master=<master's fqdn> extension_request=key=value --nodes x,y,z --modulepath /path/to/modules`

## Reference

For detailed reference information, see the [REFERENCE.md](https://github.com/puppetlabs/puppetlabs-bootstrap/blob/master/REFERENCE.md)

## Limitations

The bootstrap task currently installs the agent via the Puppet Enterprise package management tools, and FOSS repository support will be added later. See the [Puppet Enterprise](https://docs.puppet.com/pe/latest/install_agents.html) documentation for more information.

For an extensive list of supported operating systems, see [metadata.json](https://github.com/puppetlabs/puppetlabs-bootstrap/blob/master/metadata.json)

The bootstrap task is tested to work with Windows Management Framework >= v3.0+ and .NET >= v4.6 on the supported Windows operating systems.

## Development

Acceptance tests for this module leverage [puppet_litmus](https://github.com/puppetlabs/puppet_litmus).
To run the acceptance tests follow the instructions [here](https://github.com/puppetlabs/puppet_litmus/wiki/Tutorial:-use-Litmus-to-execute-acceptance-tests-with-a-sample-module-(MoTD)#install-the-necessary-gems-for-the-module).
You can also find a tutorial and walkthrough of using Litmus and the PDK on [YouTube](https://www.youtube.com/watch?v=FYfR7ZEGHoE).

If you run into an issue with this module, or if you would like to request a feature, please [file a ticket](https://tickets.puppetlabs.com/browse/MODULES/).
Every Monday the Puppet IA Content Team has [office hours](https://puppet.com/community/office-hours) in the [Puppet Community Slack](http://slack.puppet.com/), alternating between an EMEA friendly time (1300 UTC) and an Americas friendly time (0900 Pacific, 1700 UTC).

If you have problems getting this module up and running, please [contact Support](http://puppetlabs.com/services/customer-support).

If you submit a change to this module, be sure to regenerate the reference documentation as follows:

```bash
puppet strings generate --format markdown --out REFERENCE.md
```

## Getting Help

To display help for the bootstrap task, run `puppet task show bootstrap::linux` or `puppet task show bootstrap::windows`

To show help for the task CLI, run `puppet task run --help` or `bolt task run --help`

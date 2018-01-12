
# bootstrap

#### Table of Contents

1. [Description](#description)
2. [Requirements](#requirements)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the task is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Getting help - Some Helpful commands](#getting-help)

## Description

This module provides the bootstrap task. This allows you to install puppet-agent on un-puppeted hosts via the ssh transport.

## Requirements

This module requires both the `bolt` task runner and a Puppet Enterprise 2017.3 or later master to be installed on the machine from which you are running bolt commands (the controller node). Machines receiving task requests must have bash for now. (See [Limitations](#limitations) for more info.)

## Usage

To run the bootstrap task, use the bolt command, specifying the PE master from which the puppet-agent package should be installed and to which the agent should submit its certificate for signing.

#### Example: Basic usage

On the command line:
* For Linux,   run `bolt task run bootstrap::linux   master=<master's fqdn> --nodes x,y,z --modules /path/to/modules`
* For Windows, run `bolt task run bootstrap::windows master=<master's fqdn> --nodes x,y,z --modules /path/to/modules`
For all advanced examples below, simply replace `bootstrap::linux` by `bootstrap::windows` to perform the action on Windows.

#### Example: Verify the master's CA on initial connection

Optionally to validate the connection during the bootstrap process, specify the puppet master's CA cert by adding the cacert_content option:
`bolt task run bootstrap::linux master=<master's fqdn> cacert_content="$(cat /etc/puppetlabs/puppet/ssl/certs/ca.pem)" --nodes x,y,z --modules /path/to/modules`

#### Example: Specify a custom certname

Optionally to install the puppet-agent with a certname other than the fqdn of the target node, specify the custom certname:
`bolt task run bootstrap::linux master=<master's fqdn> certname=<custom certname> --nodes x,y,z --modules /path/to/modules`

#### Example: Specify custom dns alt names

Optionally to install the puppet-agent with custom dns alt names, specify the custom dns alt names:
`bolt task run bootstrap::linux master=<master's fqdn> dns_alt_names=<comma-separated list of alt names for the node> --nodes x,y,z --modules /path/to/modules`
(see [Compile master installation](https://docs.puppet.com/pe/latest/install_multimaster.html) documentation for more info).

You can also run tasks in the PE console. See PE task documentation for complete information.

## Reference

To view the available actions and parameters, on the command line, run `puppet task show bootstrap::linux` or `puppet task show bootstrap::windows` or see the bootstrap module page on the [Forge](https://forge.puppet.com/puppetlabs/bootstrap/tasks).

## Limitations

The bootstrap task currently installs the agent via the Puppet Enterprise package management tools, and FOSS repository support will be added later. See the [Puppet Enterprise](https://docs.puppet.com/pe/latest/install_agents.html) documentation for more information.

## Getting Help

To display help for the bootstrap task, run `puppet task show bootstrap::linux` or `puppet task show bootstrap::windows`

To show help for the task CLI, run `puppet task run --help` or `bolt task run --help`

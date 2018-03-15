
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

On the command line, run `bolt task run bootstrap master=<master's fqdn> --nodes x,y,z --modules /path/to/modules`

#### Example: Verify the master's CA on initial connection

Optionally to validate the connection during the boostrap process, specify the puppet master's CA cert: `bolt task run bootstrap master=<master's fqdn> cacert_content="$(cat /etc/puppetlabs/puppet/ssl/certs/ca.pem)" --nodes x,y,z --modules /path/to/modules`

#### Example: Specify a custom certname

Optionally to install the puppet-agent with a certname other than the fqdn of the target node, specify the custom certname: `bolt task run bootstrap master=<master's fqdn> certname=<custom certname> --nodes x,y,z --modules /path/to/modules`

#### Example: Specify custom dns alt names

Optionally to install the puppet-agent with custom dns alt names, specify the custom dns alt names: `bolt task run bootstrap master=<master's fqdn> dns_alt_names=<comma-separated list of alt names for the node> --nodes x,y,z --modules /path/to/modules` (see [Compile master installation](https://docs.puppet.com/pe/latest/install_multimaster.html) documentation for more info).

You can also run tasks in the PE console. See PE task documentation for complete information.

#### Example: Specify a custom_attribute

Optionally to install the puppet-agent and adding a setting to puppet.conf and including it in the custom_attributes section of csr_attributes.yaml: `bolt task run bootstrap master=<master's fqdn> custom_attribute=key=value --nodes x,y,z --modules /path/to/modules`

#### Example: Specify a extension_request

Optionally to install the puppet-agent and adding a setting to puppet.conf and including it in the extension_requests section of csr_attributes.yaml: `bolt task run bootstrap master=<master's fqdn> extension_request=key=value --nodes x,y,z --modules /path/to/modules`

## Reference

To view the available actions and parameters, on the command line, run `puppet task show bootstrap` or see the bootstrap module page on the [Forge](https://forge.puppet.com/puppetlabs/bootstrap/tasks).

## Limitations

The bootstrap task currently only runs in bash and expects unix paths to exist. Windows functionality will be added later.

The bootstrap task currently installs the agent via the Puppet Enterprise package management tools, and FOSS repository support will be added later. See the [Puppet Enterprise](https://docs.puppet.com/pe/latest/install_agents.html) documentation for more information.

## Getting Help

To display help for the bootstrap task, run `puppet task show bootstrap`

To show help for the task CLI, run `puppet task run --help` or `bolt task run --help`

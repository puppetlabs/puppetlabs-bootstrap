require 'beaker-puppet'
require 'beaker-rspec/helpers/serverspec'
require 'beaker-rspec/spec_helper'
require 'beaker/puppet_install_helper'
require 'beaker/testmode_switcher/dsl'
require 'beaker/module_install_helper'
require 'beaker-task_helper'

Dir["./spec/helpers/**/*.rb"].sort.each { |f| require f }

# We're testing the boot strapper. We don't want beaker installing the agent.
run_puppet_install_helper_on(hosts_with_role(hosts, 'master'))
configure_type_defaults_on(hosts)
install_ca_certs
install_bolt_on(hosts_with_role(hosts, 'master'))
install_module_on(hosts_with_role(hosts, 'master'))
install_module_dependencies_on(hosts_with_role(hosts, 'master'))

RSpec.configure do |c|
  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    run_puppet_access_login(user: 'admin') if pe_install?
  end
end

def linux_agents
  hosts.select {|host| host.platform !~ /windows/i}
end

def windows_agents
  agents.select { |agent| agent['platform'].include?('windows') }
end

def linux_agents_not_master
  agents.select { |agent| !agent['platform'].include?('windows') && !agent['roles'].include?('master')}
end

def master_hostname
  hosts_with_role(hosts, 'master')[0].hostname
end

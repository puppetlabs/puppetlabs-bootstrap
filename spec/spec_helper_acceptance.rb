require 'bolt_spec/run'
require 'beaker-pe'
require 'beaker-puppet'
require 'puppet'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'
require 'beaker-task_helper'
require 'beaker-task_helper/inventory'

run_puppet_install_helper
configure_type_defaults_on(hosts)
install_ca_certs unless pe_install?
install_module_on(hosts)
install_module_dependencies_on(hosts)

base_dir = File.dirname(File.expand_path(__FILE__))

def task_run(task_name, params)
  bolt_config = { 'modulepath' => File.join(Dir.pwd, 'spec', 'fixtures', 'modules') }
  run_task(task_name, 'default', params, config: bolt_config, inventory: hosts_to_inventory)
end

RSpec.configure do |c|
  # Readable test descriptions
  c.formatter = :documentation

  c.add_setting :module_path
  c.module_path = File.join(base_dir, 'fixtures', 'modules')

  # Configure all nodes in nodeset
  c.before :suite do
    run_puppet_access_login(user: 'admin') if pe_install?
  end
end

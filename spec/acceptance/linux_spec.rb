# run a test task
require 'spec_helper_acceptance'
require 'bolt_spec/run'
require 'open3'

def return_hostname
  host = if pe_install?
           master.hostname
         else
           'localhost'
         end
  host
end

describe 'bootstrap task' do
  include BoltSpec::Run
  let(:bolt_config) { { 'modulepath' => RSpec.configuration.module_path } }

  # describe 'install' do
  #   it 'installs the agent',  pending: 'Test needs re-written and nodesets fixed' do
  #     on(master, "puppet cert list #{return_hostname}").stdout.match(%r{[0-9A-F:]{95}})[0] if pe_install?
  #     result = run_task(task_name: 'bootstrap::linux', params: "master=#{return_hostname} cacert_content=\"$(cat /etc/puppetlabs/puppet/ssl/certs/ca.pem)\"")
  #     expect_multiple_regexes(result: result, regexes: [%r{Installed}, %r{Job completed. 1/1 nodes succeeded|Ran on 1 node}])
  #   end
  # end

  before(:all) do
    # bolt_config = { 'modulepath' => RSpec.configuration.module_path }
    result = run_plan('deploy_pe::provision_master', 'targets' => 'localhost', 'version' => '2021.7.8')
    expect(result['status']).to eq('success')
  end

  it 'installs Puppet agent' do
    result = run_task('bootstrap', 'localhost', { 'master' => 'localhost', 'certname' => 'testing123.com' })
    expect(result['status']).to eq('success')
  end
end

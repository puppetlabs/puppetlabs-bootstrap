# run a test task
require 'spec_helper_acceptance'

describe 'bootstrap task', unless: fact_on(default, 'osfamily') == 'windows' do
  include Beaker::TaskHelper::Inventory
  include BoltSpec::Run

  let(:hostname) do
    if pe_install?
      master.hostname
    else
      'localhost'
    end
  end
  
  describe 'install', pending "Test's need to be rewritten." do
    # This module allows puppet agents to be installed on unpuppeted host's, but all test machines
    #   have puppet by default.
    it 'installs the agent' do
      on(master, "puppet cert list #{hostname}").stdout.match(%r{[0-9A-F:]{95}})[0] if pe_install?
      # result = run_task(task_name: 'bootstrap::linux', params: "master=#{return_hostname} cacert_content=\"$(cat /etc/puppetlabs/puppet/ssl/certs/ca.pem)\"")
      result = task_run('bootstrap::linux', 'master' => hostname, 'cacert_content' => "\"$(cat /etc/puppetlabs/puppet/ssl/certs/ca.pem)\"")
      # expect_multiple_regexes(result: result, regexes: [%r{Installed}, %r{Job completed. 1/1 nodes succeeded|Ran on 1 node}])
      expect(result.first['status']).to eq 'success'
      expect(result.first['result']['_output']).to match %r{Job completed. 1/1 nodes succeeded|Ran on 1 node}
    end
  end
end

# run a test task
require 'spec_helper_acceptance'

def get_hostname
  host = if pe_install?
    master.hostname
  else
    'localhost'
         end
  host
end

describe 'bootstrap task' do
  describe 'install' do
    it 'installs the agent' do
      on(master, "puppet cert list #{get_hostname}").stdout.match(%r{[0-9A-F:]{95}})[0] if pe_install?
      result = run_task(task_name: 'bootstrap', params: "master=#{get_hostname} cacert_content=\"$(cat /etc/puppetlabs/puppet/ssl/certs/ca.pem)\"")
      expect_multiple_regexes(result: result, regexes: [%r{Installed}, %r{Job completed. 1/1 nodes succeeded|Ran on 1 node}])
    end
  end
end

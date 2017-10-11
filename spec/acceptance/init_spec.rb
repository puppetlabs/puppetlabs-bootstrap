# run a test task
require 'spec_helper_acceptance'

describe 'bootstrap task' do
  describe 'install', if: pe_install? do
    it 'installs the agent' do
      fingerprint = on(master, "puppet cert list #{master.hostname}").stdout.match(%r{[0-9A-F:]{95}})[0]
      result = run_bolt_task(task_name: 'bootstrap', params: "master=#{master.hostname} cacert_content=\"$(cat /etc/puppetlabs/puppet/ssl/certs/ca.pem)\"")
      expect_multiple_regexes(result: result, regexes: [%r{Installed}, %r{Ran on 1 node}])
    end
  end
end

# run a test task
require 'spec_helper_acceptance'

describe 'bootstrap task' do
  describe 'install', if: pe_install? do
    it 'installs the agent' do
      fingerprint = on(master, "puppet cert list #{master.hostname}").stdout.match(%r{[0-9A-F:]{95}})[0]
      result = run_bolt_task(task_name: 'bootstrap', params: "master=#{master.hostname} ca_fingerprint=#{fingerprint}")
      expect_multiple_regexes(result: result, regexes: [%r{status : installed}, %r{version : 1.\d}, %r{Job completed. 1/1 nodes succeeded}])
    end
  end
end

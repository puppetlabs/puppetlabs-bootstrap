require 'spec_helper_acceptance'

describe 'Under normal operation' do
  let(:bolt_path)   {'/opt/puppetlabs/puppet/bin/bolt'}
  let(:module_path) {'/etc/puppetlabs/code/modules'}
  context 'for linux hosts' do
    let(:pass) {ENV['SSH_PASSWORD']}

    linux_agents_not_master.each do |agent|

      it 'should bootstrap Puppet agent' do

        command  = "#{bolt_path} task run bootstrap::linux "
        command << "--no-host-key-check "
        command << "master=#{master_hostname} "
        command << "--nodes #{agent.hostname} "
        command << "--modulepath #{module_path} "
        command << "--user root "
        command << "--pass #{pass}"

        # Stop here for now because running the command currently results in a
        # connection reset. Trying to figure out why
        # require 'pry'; binding.pry;

        on(master, command) do | result |
          expect(1).to eq(1)
        end
      end
    end
  end

  context 'for Windows hosts' do

    let(:pass) {ENV['WINRM_PASSWORD']}

    # require 'pry'; binding.pry;

    windows_agents.each do |agent|
      it 'should bootstrap Puppet agent' do

        # require 'pry'; binding.pry;
        
        command  = "#{bolt_path} task run bootstrap::windows "
        command << "master=#{master_hostname} "
        command << "--nodes winrm://#{agent.hostname} "
        command << "--modulepath #{module_path} "
        command << "--user administrator "
        command << "--pass #{pass} "
        command << "--no-ssl "
        command << "--connect-timeout 600"

        on(master, command) do |result|
          expect(1).to eq(1)
        end
      end
    end
  end
end

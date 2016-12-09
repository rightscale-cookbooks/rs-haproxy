require_relative 'spec_helper'

describe 'rs-haproxy::default' do
  context 'main haproxy without ssl' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
      end.converge(described_recipe)
    end

    it 'includes rs-base::rsyslog' do
      expect(chef_run).to include_recipe('rs-base::rsyslog')
    end

    it 'creates rsyslog configuration' do
      expect(chef_run).to create_cookbook_file('/etc/rsyslog.d/10-haproxy.conf').with(
        source: 'rsyslog-10-haproxy.conf',
        backup: 0,
        mode: 0644,
        owner: 'root',
        group: 'root'
      )
    end

    it 'creates logrotate file' do
      expect(chef_run).to create_cookbook_file('/etc/logrotate.d/haproxy').with(
        source: 'logrotate-haproxy.conf',
        backup: 0,
        mode: 0644,
        owner: 'root',
        group: 'root'
      )
    end
    it 'creates the haproxy config' do
      expect(chef_run).to create_haproxy('set up haproxy.cnf')
    end
  end

  context 'ssl is enabled' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.set['rs-haproxy']['ssl_cert'] = 'certdata'
      end.converge(described_recipe)
    end
    let(:haproxy_conf_dir) { ::File.join(chef_run.node['haproxy']['source']['prefix'], chef_run.node['haproxy']['conf_dir']) }
    let(:ssl_cert_file) { ::File.join(haproxy_conf_dir, 'ssl_cert.pem') }

    it 'creates cert dir' do
      expect(chef_run).to create_directory(haproxy_conf_dir)
    end

    it 'creates cert file' do
      expect(chef_run).to create_file(ssl_cert_file).with(
        content: chef_run.node['rs-haproxy']['ssl_cert'],
        mode: 0600
      )
    end
  end
end

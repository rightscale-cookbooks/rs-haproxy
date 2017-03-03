# frozen_string_literal: true
require_relative 'spec_helper'

describe 'rs-haproxy::collectd' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['rs-base']['monitoring_type'] = 'collectd'
      node.set['rightscale']['instance_uuid'] = 'abcd1234'
      node.set['rs-base']['collectd_server'] = 'tss-4.rightscale.com'
    end.converge(described_recipe)
  end
  file_content = <<-EOF
  RS_RLL_PORT=12345
  EOF

  context 'installing collectd and setting up haproxy plugin' do
    before(:each) do
      allow(::File).to receive(:exist?).and_call_original
      allow(::File).to receive(:exist?).with('/var/run/rightlink/secret').and_return true
      allow(::File).to receive(:read).and_call_original
      allow(::File).to receive(:read).with('/var/run/rightlink/secret').and_return file_content
    end

    it 'includes collectd default recipe' do
      expect(chef_run).to include_recipe('rs-base::monitoring_collectd')
    end

    it 'installs socat package' do
      expect(chef_run).to install_apt_package('socat')
    end

    it 'does not install socat package' do
      expect(chef_run).to_not install_yum_package('socat')
    end

    it 'logs message' do
      expect(chef_run).to write_log('Setting up monitoring for HAProxy...')
    end

    it 'Put the haproxy collectd plugin script into the collectd lib directory' do
      expect(chef_run).to create_cookbook_file("#{chef_run.node['collectd']['plugin_dir']}/haproxy")
      expect(chef_run).to create_cookbook_file('/usr/share/collectd/haproxy.db')
    end

    it 'creates the collectd plug' do
      expect(chef_run).to create_collectd_plugin('haproxy')
      expect(chef_run).to create_collectd_plugin('processes')
    end
  end
end

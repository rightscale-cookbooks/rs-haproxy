# frozen_string_literal: true
require_relative 'spec_helper'

describe 'rs-haproxy::hatop' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(file_cache_path: Chef::Config[:file_cache_path]) do |node|
     node.set['rightscale']['monitoring_collector_http'] = 'tss4.rightscale.com'
    end.converge(described_recipe)
  end

  it 'installs python' do
    expect(chef_run).to install_package('python')
  end

  it 'downloads hatop' do
    expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/hatop-0.7.7.tar.gz")
  end

  it 'installs hatop' do
    expect(chef_run).to run_bash('extract and install').with(creates: '/usr/local/bin/hatop')
  end

  context 'hatop tar file does not exists' do
    before(:each) do
      File.stub(:exist?).and_call_original
      File.stub(:exist?).with("#{Chef::Config[:file_cache_path]}/hatop-0.7.7.tar.gz").and_return(false)
    end
    it 'downloads hatop' do
      expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/hatop-0.7.7.tar.gz")
    end
  end
end

# frozen_string_literal: true
require_relative 'spec_helper'

describe 'rs-haproxy::frontend' do
  context 'testing rightscale_tag include' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.set['cloud']['provider'] = 'vagrant'
        node.set['rightscale']['monitoring_collector_http'] = 'tss4.rightscale.com'
      end.converge(described_recipe)
    end

    cached(:node) { chef_run.node }

    it 'will include rightscale_tag::default' do
      expect(chef_run).to include_recipe('rightscale_tag::default')
    end
  end
end

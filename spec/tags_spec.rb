# frozen_string_literal: true
require_relative 'spec_helper'

describe 'rs-haproxy::tags' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['rightscale']['instance_uuid'] = 'abcd1234'
      node.set['rs-haproxy']['pools'] = ['default']
    end.converge(described_recipe)
  end

  context 'installing tag tools and setting up pool tags' do
    it 'includes rightscale_tag::default' do
      expect(chef_run).to include_recipe('rightscale_tag::default')
    end
    it 'will tag the loadbalancer tags' do
      expect(chef_run).to create_rightscale_tag_load_balancer('default')
    end
  end
end

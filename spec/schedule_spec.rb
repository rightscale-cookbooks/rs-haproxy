require_relative 'spec_helper'

describe 'rs-haproxy::schedule' do

  context 'rs-haproxy/schedule/enable is true' do
    let(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['rs-haproxy']['schedule']['enable'] = true
        node.set['rs-haproxy']['schedule']['interval'] = '15'
      end.converge(described_recipe)
    end

    it 'creates a crontab entry' do
      expect(chef_run).to create_cron('rs-haproxy::frontend').with(
        minute: '*/15',
        hour: '*',
        command: "rs_run_recipe --policy 'rs-haproxy::frontend' --name 'rs-haproxy::frontend'"
      )
    end
  end

  context 'rs-haproxy/schedule/enable is false' do
    let(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['rs-haproxy']['schedule']['enable'] = false
        node.set['rs-haproxy']['schedule']['interval'] = '15'
      end.converge(described_recipe)
    end

    it 'deletes the crontab entry' do
      expect(chef_run).to delete_cron('rs-haproxy::frontend').with(
        minute: '*/15',
        hour: '*',
        command: "rs_run_recipe --policy 'rs-haproxy::frontend' --name 'rs-haproxy::frontend'"
      )
    end
  end

end

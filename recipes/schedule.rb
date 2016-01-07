#
# Cookbook Name:: rs-haproxy
# Recipe:: schedule
#
# Copyright (C) 2014 RightScale, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

marker "recipe_start_rightscale" do
  template "rightscale_audit_entry.erb"
end

# From rs-haproxy/schedule/enable, determine if we are to enable or disable scheduling.
schedule_enable = node['rs-haproxy']['schedule']['enable'] == true || node['rs-haproxy']['schedule']['enable'] == 'true'

# Interval in minutes for scheduling frontend run.
interval = node['rs-haproxy']['schedule']['interval']

chef_dir='/home/rightscale/.chef'
chef_file = "#{chef_dir}/chef.json"
chef_schedule_file = "#{chef_dir}/schedule.json"
chef_json={}

# read the existing chef.json file 
# get it's content then change the runlist
# and write it back to the file
ruby_block "read chef json" do
  block do
    if File.exists?(chef_file)
      file = File.read(chef_file)
      chef_json.merge!(JSON.parse(file))
      # delete attributes
      chef_json.delete("remote_recipe") 
      chef_json.delete('rs-haproxy')
      chef_json.merge!("run_list"=>["recipe[rs-haproxy::frontend]"])
      File.write(chef_schedule_file, ::JSON.pretty_generate(chef_json))
    end
  end
end

# Run rs-haproxy::frontend on given interval.
cron "rs-haproxy::frontend" do
  user 'rightscale'
  minute "*/#{interval}"
  hour '*'
  command "sudo chef-client --json-attributes #{chef_schedule_file} --config #{chef_dir}/client.rb"
  action schedule_enable ? :create : :delete
end

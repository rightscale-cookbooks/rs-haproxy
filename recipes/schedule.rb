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

marker 'recipe_start_rightscale' do
  template 'rightscale_audit_entry.erb'
end

# From rs-haproxy/schedule/enable, determine if we are to enable or disable scheduling.
schedule_enable = node['rs-haproxy']['schedule']['enable'] == true || node['rs-haproxy']['schedule']['enable'] == 'true'

# Interval in minutes for scheduling frontend run.
interval = node['rs-haproxy']['schedule']['interval']

# Run rs-haproxy::frontend on given interval.
cron 'rs-haproxy::frontend' do
  minute "*/#{interval}"
  hour '*'
  command "rsc rl10 run_right_script /rll/run/right_script 'right_script=Haproxy Frontend - chef'"
  action schedule_enable ? :create : :delete
end

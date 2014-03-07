#
# Cookbook Name:: rs-haproxy
# Recipe:: backend_detached
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

class Chef::Recipe
  include Rightscale::RightscaleTag
end

include_recipe 'rightscale_tag::default'

# Query tags on the local application server where this recipe is run
server = list_application_server_tags(node)
instance_uuid, server_hash = server.flatten

raise "No application-related machine tags found on the server!" if server_hash["applications"].empty?

# Detach application server from the load balancer.
# An application server may server multiple applications. For each application, send a detach
# request to the corresponding load balancer serving that application.
server_hash["applications"].each do |application_name, app_hash|

  # TODO: Verify the tags required to be present on an application server exist, or else raise an exception

  # Put this backend out of service
  machine_tag "application:active_#{application_name}=false" do
    action :create
  end

  remote_request_hash = {
    'rs-haproxy' => {
      'server_id' => instance_uuid,
      'pool_name' => application_name,
      'application_action' => 'detach'
    }
  }

  file "/tmp/rs-haproxy_remote_request.json" do
    mode 0660
    content ::JSON.pretty_generate(remote_request_hash)
  end

  # Send remote recipe request
  execute "Detach me from load balancer" do
    command "rs_run_recipe --name 'rs-haproxy::frontend'" +
      " --recipient_tags 'load_balancer:active_#{application_name}=true'" +
      " --json '/tmp/rs-haproxy_remote_request.json'"
    only_if { ::File.exists?('/tmp/rs-haproxy_remote_request.json') }
  end

  file "/tmp/rs-haproxy_remote_request.json" do
    action :delete
  end
end

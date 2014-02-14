#
# Cookbook Name:: rs-haproxy
# Library:: tuning
#
# Copyright (C) 2014 RightScale, Inc.
#·
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#·
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module RsHaproxy
  module Tuning
    def self.global_config(node)
      config_hash = {
        'maxconn' => node['haproxy']['global_max_connections'],
        'user' => node['haproxy']['user'],
        'group' => node['haproxy']['group'],
        'log' => "/dev/log syslog info",
        'daemon' => true,
        'quiet' => true,
        'pidfile' => node['haproxy']['pid_file']
      }

      if node['haproxy']['enable_stats_socket']
        config_hash['stats'] = "socket #{node['haproxy']['stats_socket_path']}" +
          " user #{node['haproxy']['stats_socket_user']}" +
          " group #{node['haproxy']['stats_socket_group']}"
      end

      config_hash
    end

    def self.defaults_config(node)
      {
        'log' => 'global',
        'mode' => 'http',
        'option' => ['httplog', 'dontlognull', 'redispatch']
      }
    end

    def self.frontend_config(node, section_name)
      {
        section_name => {
          'bind' => "#{node[:haproxy][:incoming_address]}:#{node[:haproxy][:incoming_port]}",
          'default_backend' => node['rs-haproxy']['pools'].last
        }
      }
    end

    def self.backend_pool_config(node, pool_name, options = {})
      config_hash = {
        pool_name => {
          'mode' => 'http',
          'balance' => node['haproxy']['balance_algorithm'],
          'server' => []
        }
      }

      if node['haproxy']['enable_stats_socket']
        config_hash[pool_name]['stats'] = "uri #{node['rs-haproxy']['stats_uri']}"
      end

      if node['haproxy']['httpchk']
        config_hash[pool_name]['option'] = "httpchk GET #{node['haproxy']['httpchk']}"
        config_hash[pool_name]['http-check'] = 'disable-on-404'
      end

      if node['rs-haproxy']['session_stickiness']
        config_hash[pool_name]['cookie'] = 'SERVERID insert indirect nocache'
        # When cookie is enabled the haproxy.cnf should have this dummy server
        # entry for the haproxy to start without any errors
        config_hash[pool_name]['server'] << {
          'disabled-server 127.0.0.1:1' => { 'disabled' => ' ' }
        }
      end

      config_hash[pool_name].merge!(options)
      config_hash
    end

    # Adds configuration options to the backend servers in haproxy.cfg.
    #
    # @param node [Chef::Node] the chef node
    # @param options [Hash{Symbol => Fixnum, nil}] the optional parameters to add to the configuration
    #
    # @return [Hash] the server configuration hash
    #
    def self.backend_server_config(node, backend_server, options = {})
      config_hash = {
        backend_server => {
          'inter' => 300,
          'rise' => 2,
          'fall' => 3,
          'maxconn' => node['haproxy']['member_max_connections']
        }
      }

      if node['haproxy']['http_chk']
        config_hash[backend_server]['check'] = true
      end

      if node['rs-haproxy']['session_stickiness']
        config_hash[backend_server]['cookie'] = backend_server.split(' ').first
      end

      config_hash[backend_server].merge!(options)
      config_hash
    end
  end
end

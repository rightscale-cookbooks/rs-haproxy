#
# Cookbook Name:: rs-haproxy
# Library:: config
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

module RsHaproxy
  # A module for helpers to configure HAProxy.
  #
  module Config
    # Configures the global section in haproxy.cfg.
    #
    # @param node [Chef::Node] the chef node
    #
    # @return [Hash] the global config hash
    #
    def self.global(node)
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

    # Configures the default section in haproxy.cfg.
    #
    # @param node [Chef::Node] the chef node
    #
    # @return [Hash] the defaults config hash
    #
    def self.defaults(node)
      config_hash = {
        'log' => 'global',
        'mode' => 'http',
        'option' => ['httplog', 'dontlognull', 'redispatch'],
        'mode' => 'http',
        'balance' => node['haproxy']['balance_algorithm'],
      }

      if node['haproxy']['enable_stats_socket']
        config_hash['stats'] = "uri #{node['rs-haproxy']['stats_uri']}"
      end

      if node['haproxy']['httpchk']
        config_hash['option'] = "httpchk GET #{node['haproxy']['httpchk']}"
        config_hash['http-check'] = 'disable-on-404'
      end

      config_hash
    end

    # Configures the frontend section in haproxy.cfg.
    #
    # @param node [Chef::Node] the chef node
    # @param frontend_name [String] the name for the frontend section
    #
    # @return [Hash] the frontend config hash
    #
    def self.frontend(node, frontend_name)
      config_hash = {
        frontend_name => {
          'bind' => "#{node[:haproxy][:incoming_address]}:#{node[:haproxy][:incoming_port]}",
          'default_backend' => node['rs-haproxy']['pools'].last,
        }
      }
    end

    # Sets up access control lists (ACLs) in haproxy.cfg.
    #
    # @param frontend_name [String] the name for the frontend section
    # @param pool_name [String] the pool name
    #
    # @return [Hash] the ACLs config hash
    #
    def self.setup_acls(frontend_name, pool_name)
      config_hash = {
        'acl' => {},
        'use_backend' => {}
      }

      pool_name_friendly = RsHaproxy::Helper.get_friendly_pool_name(pool_name)

      acl_name = "acl_#{pool_name_friendly}"
      if pool_name.include?('/')
        config_hash['acl'][acl_name] = "path_dom -i #{pool_name}"
      else
        config_hash['acl'][acl_name] = "hdr(dom) -i #{pool_name}"
      end

      config_hash['use_backend'][pool_name_friendly] = "if #{acl_name}"

      config_hash
    end

    # Sets up the backend section for a given pool.
    #
    # @param node [Chef::Node] the chef node
    #
    # @return [Hash] the backend pool hash
    #
    def self.backend_pool(node, pool_name)
      config_hash = {
        pool_name => {}
      }

      if node['rs-haproxy']['session_stickiness']
        config_hash[pool_name]['cookie'] = 'SERVERID insert indirect nocache'
        # When cookie is enabled the haproxy.cnf should have this dummy server
        # entry for the haproxy to start without any errors
        config_hash[pool_name]['server'] ||= []
        config_hash[pool_name]['server'] << {
          'disabled-server 127.0.0.1:1' => {'disabled' => true}
        }
      end

      config_hash
    end

    # Adds configuration options to the backend servers in haproxy.cfg.
    #
    # @param node [Chef::Node] the chef node
    # @param backend_server [String] the server to be added to the backend section
    # @param options [Hash] the optional parameters to add to the server
    #
    # @return [Hash] the server configuration hash
    #
    def self.backend_server(node, backend_server, options = {})
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

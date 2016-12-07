require 'serverspec'
require 'pathname'
require 'socket'
require 'csv'
require 'json'
require 'rubygems/dependency_installer'

# server_spec requires Gems to be installed in a specific path so the following is needed to make machine_tag
# available for testing
installer = Gem::DependencyInstaller.new
installer.install('machine_tag')
Gem.clear_paths

require 'machine_tag'

# Helper function to sort through the haproxy.cfg
#
# @param config_file [String] the name of the config file (/var/haproxy/haproxy.cfg)
# @param regex_group [String] is the section name in the haproxy config (global, default, ....)
# @param regex_setting [String] is a string used as a regex to match setting underl group
# return true if found, false otherwise.
#
def find_haproxy_setting(config_file, regex_group, regex_setting)
  hapcfg = IO.readlines(config_file)
  hapcfg.reject! { |line| line =~ /^#/ || line =~ /^\s*#/ || line =~ /^\s*$/ }

  begin_non_white_space = /^\S/
  in_group = false

  hapcfg.each do |line|
    if in_group == false && line =~ begin_non_white_space && line =~ /#{regex_group}/
      in_group = true
      next
    elsif in_group == true && line =~ begin_non_white_space
      in_group = false
    elsif in_group == true && line =~ /#{regex_setting}/
      return true
    end
  end

  false
end

# Helper function to sort through haproxy socket info.
#
# @param regex_setting [String] is the setting we want to look the value for.
# returns the value of the parameter

def haproxy_info(regex_setting)
  haproxy_show_info.each do |line|
    if line =~ /#{regex_setting}/i
      return line.match(/#{regex_setting}:\s+(.*)/i).captures[0]
      end
  end

  nil
end

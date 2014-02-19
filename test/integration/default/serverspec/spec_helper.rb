require 'serverspec'
require 'pathname'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

# Helper function to sort through the haproxy.cfg
# 
# @param config_file the name of the config file (/var/haproxy/haproxy.cfg)
# @param regex_group is the section name in the haproxy config (global, default, ....)
# @param regex_setting is a string used as a regex to match setting underl group
# return true if found, false otherwise.
#
def find_haproxy_setting(config_file,  regex_group, regex_setting)
  hapcfg = IO.readlines( config_file )
  hapcfg.reject! { |line|  line =~ /^#/ || line =~ /^\s*#/  || line =~ /^\s*$/ }

  begin_non_white_space = /^\S/
  in_group = false

  hapcfg.each do |line|
    if in_group == false and line =~ begin_non_white_space and line =~ /#{regex_group}/
       in_group = true
       next
    elsif in_group == true and line =~ begin_non_white_space
       in_group = false
    elsif in_group == true and line =~ /#{regex_setting}/
        return true
    end
  end

  return false
end

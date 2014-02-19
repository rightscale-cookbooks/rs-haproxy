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
  hacfg = IO.readlines( config_file )
  hacfg = hacfg.reject! { |line|  line =~ /^#/ || line =~ /^\s*#/  || line =~ /^\s*$/ }
  
  i = 0 
  while i < hacfg.length() do
    if hacfg[i] =~ /^\S/ and hacfg[i] =~ /#{regex_group}/
        i += 1
        while hacfg[i] =~ /^\s/ do
           if hacfg[i] =~ /#{regex_setting}/ 
              return true 
           end 
           i += 1
        end 
    end 
    i += 1
  end 
  return false
end

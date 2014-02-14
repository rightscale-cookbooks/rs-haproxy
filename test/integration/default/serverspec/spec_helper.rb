require 'serverspec'
require 'pathname'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

# Helper function to sort through the haproxy.cfg
# returns true if setting is found under give group.
def find_haproxy_setting(config_file,  regex_group, regex_setting)
  hacfg = IO.readlines( config_file )
  hacfg = hacfg.reject! { |line|  line =~ /^#/ || line =~ /.*#/ }
  
  i = 0 
  while i < hacfg.length() do
    if hacfg[i] =~ /^\S/ and hacfg[i] =~ regex_group
        i += 1
        while hacfg[i] =~ /^\s/ do
           if hacfg[i] =~ regex_setting 
              return TrueClass 
           end 
           i += 1
        end 
    end 
    i += 1
  end 
  return FalseClass
end

require 'serverspec'
require 'pathname'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

# Helper function to sort through the haproxy.cfg
# returns true if setting is found under give group.
def find_haproxy_setting(config_file,  regex_group, regex_setting)
  splitfile = IO.readlines( config_file ).reject! { |c| c.empty? || c =~ /^#/ || c =~ /.*#/ }
  
  i = 0 
  while i < splitfile.length() do
    if splitfile[i] =~ /^\S/ and splitfile[i] =~ regex_group
        i += 1
        while splitfile[i] =~ /^\s/ do
           if splitfile[i] =~ regex_setting 
              return TrueClass 
           end 
           i += 1
        end 
    end 
    i += 1
  end 
  return FalseClass
end

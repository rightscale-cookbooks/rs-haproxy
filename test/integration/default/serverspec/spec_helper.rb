require 'serverspec'
require 'pathname'
require 'socket'
require 'csv'

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

# Helper function to sort through haproxy socket info.
#
# @param regex_setting is the setting we want to look the value for.
# returns the value of the parameter
#
# This function reads the haproxy socket.  It parses through the info section
# and puts the data into a csv format, from which we can request values
# given the parameter name.
def haproxy_info( regex_setting )
  socket = UNIXSocket.new('/var/run/haproxy.sock')
  socket.puts('show info')
  content = ""
  while line = socket.gets do
    content << line.split(':').join(',')
  end
  
  csv_content = CSV.parse(content)
  
  csv_content.each do |line|
    if line[0] =~ /#{regex_setting}/i 
     return line[1].strip()
    end
  end

  return nil
end


# Helper function to sort through haproxy socket info.
#
# @param regex_setting is the setting we want to look the value for.
# returns the value of the parameter
#
# This function reads the haproxy socket.  It parses through the info section
# and puts the data into a csv format, from which we can request values
# given the parameter name.
def haproxy_stat( regex_pxname, regex_svname, regex_query )

  begin
    socket = UNIXSocket.new('/var/run/haproxy.sock')
    socket.puts('show stat')
  rescue
    retry
  end

  content = ""
  while line = socket.gets do
    content << line
  end
  
  csv_content = CSV.parse(content)
  index  = csv_content[0].index("#{regex_query}")

  csv_content.each do |line|
    if line[0] =~ /#{regex_pxname}/i and line[1] =~ /#{regex_svname}/ 
     return line[index].strip()
    end
  end

  return nil
end



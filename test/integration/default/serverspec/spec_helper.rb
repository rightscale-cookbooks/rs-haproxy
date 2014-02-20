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
# @param regex_setting [String] is the setting we want to look the value for.
# returns the value of the parameter
#
# This function reads the haproxy socket.  It parses through the info section
# and puts the data into a csv format, from which we can request values
# given the parameter name.
def haproxy_info( regex_setting )
 
  socket = nil

  10.times do
    begin
      socket = UNIXSocket.new('/var/run/haproxy.sock')
      socket.puts('show info')
      break
    rescue
      next
    end
  end

  while line = socket.gets do
    if line =~ /#{regex_setting}/i
      return line.match(/#{regex_setting}:\s+(.*)/i).captures[0]
    end
  end

  return nil
end


# Helper function to sort through haproxy socket info.
#
# @param pxname [String] the first value in row we want to select.
# @param svname [String] the second value in the row we want to select.
# @param column [String] the name of the column to select from
# returns the value found at the selected row and column.
#
# This function reads the haproxy socket.  It parses through the info section
# and puts the data into a csv format.  The row is selected by providing the 
# first two values in the row.  The colum is slected by name.
def haproxy_stat( pxname, svname, column )

  socket = nil

  10.times do 
    begin
      socket = UNIXSocket.new('/var/run/haproxy.sock')
      socket.puts('show stat')
      break
    rescue
      next
    end
  end

  content = ""
  while line = socket.gets do
    content << line
  end
  
  csv_content = CSV.parse(content)
  index  = csv_content[0].index("#{column}")

  csv_content.each do |line|
    if line[0] =~ /#{pxname}/i and line[1] =~ /#{svname}/ 
     return line[index].strip()
    end
  end

  return nil
end



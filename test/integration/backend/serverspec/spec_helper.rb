require 'serverspec'
require 'pathname'
require 'socket'
require 'csv'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

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



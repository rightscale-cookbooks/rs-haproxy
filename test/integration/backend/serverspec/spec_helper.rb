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
# first two values in the row.  The column is selected by name.

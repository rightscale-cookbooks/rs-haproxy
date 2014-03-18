#backend

require 'spec_helper'
require 'pathname'
require 'socket'
require 'csv'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

# Helper function to sort through haproxy socket info.
#
# @param pxname [String] the first value in row we want to select.
# @param svname [String] the second value in the row we want to select.
# Returns the value found at the selected row and under the status column
#
def haproxy_stat( pxname, svname )

  csv_content = haproxy_show_stat
  index  = csv_content[0].index("status")

  csv_content.each do |line|
    if line[0] =~ /#{pxname}/i and line[1] =~ /#{svname}/
     return line[index].strip()
    end
  end

  return nil
end

describe service("haproxy") do
  it { should be_enabled }
  it { should be_running }
end

describe "Verify correct port set and redirects to backend server." do
  describe "Accessing ip:port should return redirect message" do
    describe command('curl --silent 33.33.33.5:80 | grep -o "You are being.*redirected"') do
      it { should return_stdout 'You are being <a href="http://33.33.33.5/login">redirected' }
    end
  end
  describe "Should return the correct Discourse webpage greeting from backend" do
    describe command('curl --silent 33.33.33.5/login | grep -o "Welcome to RightScale RightScale Discourse"') do
      it { should return_stdout 'Welcome to RightScale RightScale Discourse'}
    end
  end
  describe "Should return backend if we specify redirect but not /login" do
    describe command('curl --silent -L 33.33.33.5 | grep -o "Welcome to RightScale RightScale Discourse"') do
      it { should return_stdout 'Welcome to RightScale RightScale Discourse'}
    end
  end
end

describe "Verify settings through haproxy socket" do

  # This function reads the haproxy socket.  It parses through the info section
  # and puts the data into a csv format.  The row is selected by providing the
  # first two values in the row.  The column is slected by name.
  #
  let(:haproxy_show_stat) do
    begin
      UNIXSocket.open('/var/run/haproxy.sock') do |socket|
        socket.puts('show stat')
        CSV.parse(socket.read)
      end
    rescue Errno::EPIPE
      retry
    end
  end

  [
    ["all_requests", "FRONTEND",          "OPEN"],
    ["app1",         "disabled-server",   "MAINT"],
    ["app1",         "app1host2",         "no check"],
    ["app1",         "app1host1",         "no check"],
    ["app1",         "BACKEND",           "UP"],
    ["app2",         "disabled-server",   "MAINT"],
    ["app2",         "app2host1",         "no check"],
    ["app2",         "BACKEND",           "UP"],
    ["app3",         "disabled-server",   "MAINT"],
    ["app3",         "app3host1",         "no check"],
    ["app3",         "BACKEND",           "UP"],
    ["default",      "disabled-server",   "MAINT"],
    ["default",      "discourse",         "no check"],
    ["default",      "BACKEND",           "UP"]
  ].each do |pool_name, server, status|
    it "#{pool_name} #{server} should have status of #{status}" do
      haproxy_stat(pool_name, server).should eq(status)
    end
  end
end

require 'spec_helper'
require 'pathname'
require 'socket'
require 'csv'

# Helper variable to sort through haproxy socket info.

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
  [
    ["all_requests", "FRONTEND",          "status", "OPEN"],
    ["app1",         "disabled-server",   "status", "MAINT"],
    ["app1",         "app1host2",         "status", "no check"],
    ["app1",         "app1host1",         "status", "no check"],
    ["app1",         "BACKEND",           "status", "UP"],
    ["app2",         "disabled-server",   "status", "MAINT"],
    ["app2",         "app2host1",         "status", "no check"],
    ["app2",         "BACKEND",           "status", "UP"],
    ["app3",         "disabled-server",   "status", "MAINT"],
    ["app3",         "app3host1",         "status", "no check"],
    ["app3",         "BACKEND",           "status", "UP"],
    ["default",      "disabled-server",   "status", "MAINT"],
    ["default",      "discourse",         "status", "no check"],
    ["default",      "BACKEND",           "status", "UP"]
  ].each do |pool_name, server, status, status_state|
    it "#{pool_name} #{server} should have #{status} of #{status_state}" do
      csv_content = haproxy_show_stat
      index  = csv_content[0].index("#{status}")
      csv_content.each do |line|
        if line[0] =~ /#{pool_name}/i and line[1] =~ /#{server}/
          return line[index].strip()
        end
      end
    end
  end
end

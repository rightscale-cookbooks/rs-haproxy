require 'spec_helper'
require 'pathname'
require 'socket'
require 'csv'

# Helper function to sort through haproxy socket info.
#
# @param pxname [String] the first value in row we want to select.
# @param svname [String] the second value in the row we want to select.
# Returns the value found at the selected row and under the status column
#
def haproxy_stat(pxname, svname)
  csv_content = haproxy_show_stat
  index  = csv_content[0].index("status")

  csv_content.each do |line|
    if line[0] =~ /#{pxname}/i and line[1] =~ /#{svname}/
     return line[index].strip()
    end
  end

  return nil
end

# Helper function to add to entry to /etc/hosts.
#
def add_host
  entry_line = "192.0.2.2 www.example.com test.example.com"

  if open('/etc/hosts') { |f| f.grep(/^#{entry_line}$/).empty? }
    open('/etc/hosts', 'a') { |p| p.puts "\n#{entry_line}" }
  end

  if open('/etc/hosts') { |f| f.grep(/^#{entry_line}$/).empty? }
    false
  else
    true
  end

end

config_file = '/usr/local/etc/haproxy/haproxy.cfg'

describe service("haproxy") do
  it { should be_enabled }
  it { should be_running }
end

describe port(445) do
  it { should be_listening }
end

describe "Verify frontend settings in haproxy.cfg file" do
  [
    ["frontend all_requests", "default_backend example"],
    ["frontend all_requests", "use_backend test_example if acl_test_example"],
    ["frontend all_requests", "use_backend appserver if acl_appserver"],
    ["frontend all_requests", "use_backend example if acl_example"],
    ["frontend all_requests", "bind 0.0.0.0:80"],
    ["frontend all_requests", "bind 0.0.0.0:445 ssl crt /usr/local/etc/haproxy/ssl_cert.pem"],
    ["frontend all_requests", "redirect scheme https if !{ ssl_fc }"],
  ].each do |pair|
    it "#{pair.first} should contain #{pair.last}" do
      find_haproxy_setting(config_file, pair.first, pair.last).should == true
    end
  end
end

describe "Verify backend configuration" do
  before(:all) do
    raise "/etc/hosts not updated correctly" unless add_host
  end

  context "SSL certificate not passed to the curl call" do
    context "Connecting to port 445" do
      describe command([
        'curl',
        '--silent',
        'https://www.example.com:445'
      ].join(' ')) do
        its(:exit_status) { should eq 60 }
      end
    end

    # Connecting to port 80 should redirect to HTTPS
    context "Connecting to port 80" do
      describe command([
        'curl',
        '--silent',
        '--write-out "HTTP Response Code: %{http_code}\nRedirect URL: %{redirect_url}\n"',
        'http://www.example.com'
      ].join(' ')) do
        its(:stdout) do
          should match /HTTP Response Code: 302/
          should match /Redirect URL: https:\/\/www.example.com\//
        end
      end
    end
  end

  context "SSL certificate passed to the curl call" do
    describe command([
      'curl',
      '--silent',
      '--cacert /usr/local/etc/haproxy/ssl_cert.pem',
      'https://www.example.com:445'
    ].join(' ')) do
      its(:stdout) { should match /Basic html serving succeeded\./ }
    end

    context "When application servers are attached to HAProxy pools" do
      describe "Verify if HAProxy serves pages from all application servers" do
        describe command([
          'curl',
          '--silent',
          '--cacert /usr/local/etc/haproxy/ssl_cert.pem',
          '--cookie-jar /tmp/cookie',
          'https://www.example.com:445;',
          'cat /tmp/cookie'
        ].join(' ')) do
          its(:stdout) { should match /03-ABCDEFGH0123/ }
        end

        describe command([
          'curl',
          '--silent',
          '--cacert /usr/local/etc/haproxy/ssl_cert.pem',
          '--cookie-jar /tmp/cookie',
          'https://www.example.com:445/appserver/;',
          'cat /tmp/cookie'
        ].join(' ')) do
          its(:stdout) { should match /02-ABCDEFGH0123/ }
        end

        describe command([
          'curl',
          '--silent',
          '--cacert /usr/local/etc/haproxy/ssl_cert.pem',
          '--cookie-jar /tmp/cookie',
          'https://test.example.com:445;',
          'cat /tmp/cookie'
        ].join(' ')) do
          its(:stdout) { should match /01-ABCDEFGH0123/ }
        end
      end
    end
  end
end

describe "Verify settings through haproxy socket" do

  # This function reads the haproxy socket.  It parses through the info section
  # and puts the data into a csv format.  The row is selected by providing the
  # first two values in the row.  The column is selected by name.
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
    ["all_requests", "FRONTEND", "OPEN"],
    ["test_example", "disabled-server", "MAINT"],
    ["test_example", "01-ABCDEFGH0123", "no check"],
    ["test_example", "BACKEND", "UP"],
    ["appserver", "disabled-server", "MAINT"],
    ["appserver", "02-ABCDEFGH0123", "no check"],
    ["appserver", "BACKEND", "UP"],
    ["example", "disabled-server", "MAINT"],
    ["example", "03-ABCDEFGH0123", "no check"],
    ["example", "BACKEND", "UP"],
  ].each do |pool_name, server, status|
    it "#{server} in the pool #{pool_name} should have status of #{status}" do
      haproxy_stat(pool_name, server).should eq(status)
    end
  end
end

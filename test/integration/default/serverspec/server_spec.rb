require 'spec_helper'

describe file("/etc/haproxy/haproxy.cfg") do
  it { should be_file }
end

describe service("haproxy") do
  it { should be_enabled }
  it { should be_running }
end

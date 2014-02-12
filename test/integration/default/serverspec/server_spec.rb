require 'spec_helper'


describe service("haproxy") do
  it { should be_enabled }
  it { should be_running }
end

include_recipe 'haproxy::tuning'
include_recipe 'sysctl::default'

set_limit '*' do
  type 'soft'
  item 'nofile'
  value 200_000
  use_system true
end

set_limit '*' do
  type 'soft'
  item 'nofile'
  value 200_000
  use_system true
end

sysctl_param 'net.ipv4.tcp_tw_reuse' do
  value 1
end

sysctl_param 'net.ipv4.ip_local_port_range' do
  value '1024 65535'
end

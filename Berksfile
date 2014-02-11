site :opscode

metadata

cookbook 'haproxy', github: 'hw-cookbooks/haproxy'
cookbook 'collectd', github: 'EfrainOlivares/chef-collectd', ref: 'ec50609ed6eb193e0411f30aced91befa571940f'

group :integration do
  cookbook 'apt', '~> 2.3.0'
  cookbook 'yum', '~> 2.4.4'
end

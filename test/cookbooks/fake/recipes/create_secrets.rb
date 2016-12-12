file '/var/run/rightlink/secret' do
  content 'RS_RLL_PORT=12345'
  action :nothing
end.run_action(:create)

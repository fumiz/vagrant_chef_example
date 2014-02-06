template 'default.conf' do
  action :create
  path '/etc/nginx/conf.d/default.conf'
  source 'default.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  notifies :reload,'service[nginx]'
end
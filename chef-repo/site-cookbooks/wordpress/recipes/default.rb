#
# Cookbook Name:: wordpress
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#
# Cookbook Name:: wordpress
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'wordpress::env'

wordpress_file = "#{Chef::Config[:file_cache_path]}/wordpress.tar.gz"

directory node['wordpress']['dir'] do
  action :create
  owner 'nginx'
  group 'nginx'
  mode  '00707'

  notifies :create, 'remote_file[download-wordpress]', :immediately
  notifies :run, 'execute[extract-wordpress]', :immediately
end

remote_file 'download-wordpress' do
  path wordpress_file
  source node['wordpress']['url']
  action :nothing
end

execute 'extract-wordpress' do
  command "tar xf #{wordpress_file} -C #{node['wordpress']['parent_dir']}"
  creates "#{node['wordpress']['dir']}/index.php"
  action :nothing
end

template "#{node['wordpress']['dir']}/wp-config.php" do
  path "#{node['wordpress']['dir']}/wp-config.php"
  source 'wordpress/wp-config.php.erb'
  variables(
      :db_name          => node['wordpress']['mysql']['dbname'],
      :db_user          => node['wordpress']['mysql']['user'],
      :db_password      => node['wordpress']['mysql']['password'],
      :db_host          => 'localhost',
      :auth_key         => node['wordpress']['keys']['auth'],
      :secure_auth_key  => node['wordpress']['keys']['secure_auth'],
      :logged_in_key    => node['wordpress']['keys']['logged_in'],
      :nonce_key        => node['wordpress']['keys']['nonce'],
      :auth_salt        => node['wordpress']['salt']['auth'],
      :secure_auth_salt => node['wordpress']['salt']['secure_auth'],
      :logged_in_salt   => node['wordpress']['salt']['logged_in'],
      :nonce_salt       => node['wordpress']['salt']['nonce'],
      :language         => node['wordpress']['language']
  )
  action :create
end

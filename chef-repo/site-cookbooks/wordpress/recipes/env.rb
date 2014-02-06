=begin
integrate nginx
=end
package 'nginx' do
  action :install
end

service 'nginx' do
  supports :restart => true, :stop => true, :reload => true

  action [:enable, :start]
end

directory '/var/log/nginx/default' do
  owner 'nginx'
  group 'nginx'
  mode 00700
  action :create
end

directory '/opt/local/www' do
  owner 'nginx'
  group 'nginx'
  mode 00707
  action :create
  recursive true
end

template 'nginx.conf' do
  owner 'root'
  group 'root'
  mode 0644

  path '/etc/nginx/nginx.conf'
  source 'nginx/nginx.conf.erb'

  notifies :reload, 'service[nginx]'
end

template 'default.conf' do
  owner 'root'
  group 'root'
  mode 0644

  path '/etc/nginx/conf.d/default.conf'
  source 'nginx/default.conf.erb'

  notifies :reload, 'service[nginx]'
end

template 'fastcgi.conf' do
  owner 'root'
  group 'root'
  mode 0644

  path '/etc/nginx/fastcgi.conf'
  source 'nginx/fastcgi.conf.erb'

  notifies :reload, 'service[nginx]'
end

=begin
integrate PHP
=end
PHP_PACKAGES = %w(php-mysql php-common php php-cgi php-fpm php-gd php-mbstring)
PHP_PACKAGES.each {|package_name|
  package package_name do
    action :install
  end
}

service 'php-fpm' do
  supports :restart => true, :stop => true, :reload => true

  action [:enable, :start]
end

template 'www.conf' do
  owner 'root'
  group 'root'
  mode 0644

  path '/etc/php-fpm.d/www.conf'
  source 'php-fpm/www.conf.erb'

  notifies :reload, 'service[php-fpm]'
end

template 'php.ini' do
  owner 'root'
  group 'root'
  mode 0644

  path '/etc/php.ini'
  source 'php-fpm/php.ini.erb'

  notifies :reload, 'service[php-fpm]'
end

directory '/var/lib/php/session' do
  owner 'nginx'
  group 'nginx'
  action :create
end

=begin
add MySQL
=end
package 'mysql-server' do
  action :install
end

service 'mysqld' do
  supports :restart => true, :stop => true, :reload => true

  action [:enable, :start]
end

template '/etc/my.cnf' do
  owner 'root'
  group 'root'
  mode 0644

  path '/etc/my.cnf'
  source 'mysql/my.cnf.erb'

  notifies :restart, 'service[mysqld]'
end

execute 'assign-root-password' do
  command "/usr/bin/mysqladmin  -u root password #{node['mysql']['server_root_password']}"
  action :run
  only_if "/usr/bin/mysql -u root -e 'show databases;'"
  notifies :create, 'template[mysql-grants]', :immediately
  notifies :run, 'execute[install-grants]', :immediately
  notifies :delete, 'template[mysql-grants]', :immediately
end

template 'mysql-grants' do
  action :nothing

  owner 'root'
  group 'root'
  mode 0644

  path '/tmp/mysql-grants.sql'
  source 'mysql/mysql-grants.sql.erb'
end

execute 'install-grants' do
  action :nothing
  command "/usr/bin/mysql -u root -p#{node['mysql']['server_root_password']} < /tmp/mysql-grants.sql"
end

=begin
MySQL with Wordpress
=end
execute 'install-mysql-wordpress' do
  action :run
  command <<-EOS
    mysql -uroot -p#{node['mysql']['server_root_password']} -e"CREATE DATABASE #{node['wordpress']['mysql']['dbname']};"
    mysql -uroot -p#{node['mysql']['server_root_password']} -e"GRANT ALL ON #{node['wordpress']['mysql']['dbname']}.* TO '#{node['wordpress']['mysql']['user']}'@'localhost' IDENTIFIED BY '#{node['wordpress']['mysql']['password']}';"
    mysql -uroot -p#{node['mysql']['server_root_password']} -e"FLUSH PRIVILEGES;"
  EOS
  not_if "/usr/bin/mysql -u #{node['wordpress']['mysql']['user']} -p#{node['wordpress']['mysql']['password']} -e 'show databases;'"
end

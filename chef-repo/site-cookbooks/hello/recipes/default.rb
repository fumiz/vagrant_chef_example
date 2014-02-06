#
# Cookbook Name:: hello
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

execute 'hello' do
  command 'echo hello >> /tmp/hello.txt'
  not_if { File.exists?('/tmp/hello.txt') }
end
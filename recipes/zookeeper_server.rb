#
# Cookbook Name:: cloudera
# Recipe:: zookeeper_server
#
# Author:: Istvan Szukacs (<istvan.szukacs@gmail.com>)
# Copyright 2012, Riot Games
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include_recipe "cloudera"

if node['hadoop']['cdh_major_version'] == '3'
  package "hadoop-zookeeper-server"
else
  package "zookeeper-server"
end

if Chef::Config[:solo]
  my_id = node['zookeeper']['myid']
else
  # TODO: use search to find other zookeeper servers and choose myid accordingly
end

template "/etc/zookeeper/conf/zoo.cfg" do
  source "zoo.cfg.erb"
  mode 0755
  owner "zookeeper"
  group "zookeeper"
  action :create
  variables :options => node['zookeeper']
end

if node['hadoop']['cdh_major_version'] == '3'
  service_name = "hadoop-zookeeper-server"
else
  service_name = "zookeeper-server"
end

data_dir = node['zookeeper']['dataDir']

directory "/var/log/zookeeper" do
  mode 0755
  owner "zookeeper"
  group "zookeeper"
  action :create
  recursive true
end

unless File.exists?(data_dir)
  Chef::Log.info "Initializing zookeeper"

  directory data_dir do
    mode 0755
    owner "zookeeper"
    group "zookeeper"
    action :create
    recursive true
  end

  execute "#{service_name}-initialize" do
    user    "zookeeper"
    group   "zookeeper"
    command "#{service_name}-initialize --configfile=/etc/zookeeper/conf/zoo.cfg --myid=#{my_id}"
  end
end

service service_name do
  action [ :start, :enable ]
end

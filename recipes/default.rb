#
# Cookbook Name:: cloudera
# Recipe:: default
#
# Author:: Cliff Erson (<cerson@me.com>)
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

include_recipe "cloudera::repo"

node['hadoop']['cdh_major_version'] = node['hadoop']['release'][0..0]

if node['hadoop']['cdh_major_version'] == '3'
  package "hadoop-#{node['hadoop']['version']}"
  package "hadoop-#{node['hadoop']['version']}-native"
else
  package "hadoop"
  package "hadoop-hdfs"
end
package "nscd"

service "nscd" do
  action [ :start, :enable ]
end

# need to set JAVA_HOME for hadoop
template "/etc/profile.d/cloudera-hadoop-java.sh" do
  source "profile-java.sh.erb"
  mode 0755
  owner "root"
  group "root"
  action :create
  variables :java_home => node['java']['java_home']
end

chef_conf_dir = node['hadoop']['conf_dir']

directory chef_conf_dir do
  mode 0755
  owner "root"
  group "root"
  action :create
  recursive true
end

#namenode search is broken
#namenode = find_cloudera_namenode(node.chef_environment)
#unless namenode
#  Chef::Log.fatal "[Cloudera] Unable to find the cloudera namenode!"
#  raise
#end

core_site_vars = { :options => node['hadoop']['core_site'] }

#core_site_vars[:options]['fs.default.name'] = "hdfs://#{namenode[:ipaddress]}:#{node['hadoop'][:namenode_port]}"

template "#{chef_conf_dir}/core-site.xml" do
  source "generic-site.xml.erb"
  mode 0644
  owner "hdfs"
  group "hdfs"
  action :create
  variables core_site_vars
end

#secondary_namenode = search(:node, "chef_environment:#{node.chef_environment} and recipes:cloudera\\:\\:hadoop_secondary_namenode_server").first

hdfs_site_vars = { :options => node['hadoop']['hdfs_site'] }
#hdfs_site_vars[:options]['fs.default.name'] = "hdfs://#{namenode[:ipaddress]}:#{node['hadoop'][:namenode_port]}"
# TODO dfs.secondary.http.address should have port made into an attribute - maybe
#hdfs_site_vars[:options]['dfs.secondary.http.address'] = "#{secondary_namenode[:ipaddress]}:50090" if secondary_namenode

template "#{chef_conf_dir}/hdfs-site.xml" do
  source "generic-site.xml.erb"
  mode 0644
  owner "hdfs"
  group "hdfs"
  action :create
  variables hdfs_site_vars
end

#jobtracker = search(:node, "chef_environment:#{node.chef_environment} AND recipes:cloudera\\:\\:hadoop_jobtracker").first

mapred_site_vars = { :options => node['hadoop']['mapred_site'] }
#mapred_site_vars[:options]['mapred.job.tracker'] = "#{jobtracker[:ipaddress]}:#{node['hadoop'][:jobtracker_port]}" if jobtracker

template "#{chef_conf_dir}/mapred-site.xml" do
  source "generic-site.xml.erb"
  mode 0644
  owner "hdfs"
  group "hdfs"
  action :create
  variables mapred_site_vars
end

template "#{chef_conf_dir}/hadoop-env.sh" do
  mode 0755
  owner "hdfs"
  group "hdfs"
  action :create
  variables( :options => node['hadoop']['hadoop_env'] )
end

template node['hadoop']['mapred_site']['mapred.fairscheduler.allocation.file'] do
  mode 0644
  owner "hdfs"
  group "hdfs"
  action :create
  variables node['hadoop']['fair_scheduler']
end

default_prop_file = File.join(File.expand_path("..", __FILE__), "..", "attributes", "log4j-cdh#{node['hadoop']['cdh_major_version']}.properties")
log4j_prop_keys = []
log4j_props = {}
File.new(default_prop_file).lines.each do |line|
  key, value = line.strip!.split('=', 2)
  key.strip!
  if key.size > 0 && key[0..0] != '#'
    log4j_prop_keys << key
    log4j_props[key] = value
  end
end
(node['hadoop']['log4j'] || {}).each do |key, value|
  key.strip!
  unless log4j_props.contains?(key)
    log4j_prop_keys << key
  end
  log4j_props[key] = value
end

template "#{chef_conf_dir}/log4j.properties" do
  source "generic.properties.erb"
  mode 0644
  owner "hdfs"
  group "hdfs"
  action :create
  variables( :properties => node['hadoop']['log4j'] )
end

template "#{chef_conf_dir}/hadoop-metrics.properties" do
  source "generic.properties.erb"
  mode 0644
  owner "hdfs"
  group "hdfs"
  action :create
  variables( :properties => node['hadoop']['hadoop_metrics'] )
end

# Create the master and slave files
unless Chef::Config[:solo]
  namenode_servers = search(:node, "chef_environment:#{node.chef_environment} AND recipes:cloudera\\:\\:hadoop_namenode OR recipes:cloudera\\:\\:hadoop_secondary_namenode")
  masters = namenode_servers.map { |node| node['ipaddress'] }

  template "#{chef_conf_dir}/masters" do
    source "master_slave.erb"
    mode 0644
    owner "hdfs"
    group "hdfs"
    action :create
    variables( :nodes => masters )
  end

  datanode_servers = search(:node, "chef_environment:#{node.chef_environment} AND recipes:cloudera\\:\\:hadoop_datanode")
  slaves = datanode_servers.map { |node| node['ipaddress'] }

  template "#{chef_conf_dir}/slaves" do
    source "master_slave.erb"
    mode 0644
    owner "hdfs"
    group "hdfs"
    action :create
    variables( :nodes => slaves )
  end
end

if node['hadoop']['hdfs_site']['topology.script.file.name']
  topology_dir = File.dirname(node['hadoop']['hdfs_site']['topology.script.file.name'])
  topology = { :options => node['hadoop']['topology'] }

  directory topology_dir do
    mode 0755
    owner "hdfs"
    group "hdfs"
    action :create
    recursive true
  end

  template node['hadoop']['hdfs_site']['topology.script.file.name'] do
    source "topology.rb.erb"
    mode 0755
    owner "hdfs"
    group "hdfs"
    action :create
    variables topology
  end
end

hadoop_tmp_dir = File.dirname(node['hadoop']['core_site']['hadoop.tmp.dir'])

directory hadoop_tmp_dir do
  mode 0777
  owner "hdfs"
  group "hdfs"
  action :create
  recursive true
end

execute "update hadoop alternatives" do
  if node['hadoop']['cdh_major_version'] == '3'
    alternative_link = "/etc/hadoop-#{node['hadoop']['version']}/conf"
    alternative_name = "hadoop-#{node['hadoop']['version']}-conf"
  else
    alternative_link = "/etc/hadoop/conf"
    alternative_name = "hadoop-conf"
  end

  case node['platform']
  when "redhat", "centos", "scientific", "fedora"
    command "alternatives --install #{alternative_link} #{alternative_name} #{chef_conf_dir} 50"
  when "debian", "ubuntu"
    command "update-alternatives --install #{alternative_link} #{alternative_name} #{chef_conf_dir} 50"
  end
end

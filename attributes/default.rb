#
# Cookbook Name:: cloudera
# Attributes:: default
#
# Author:: Cliff Erson (<cerson@me.com>)
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

default['hadoop']['version'] = "0.20"
default['hadoop']['release'] = "3u3"

default['hadoop']['conf_dir'] = "/etc/hadoop-#{node['hadoop']['version']}/conf.chef"

default['hadoop']['namenode_port']   = "54310"
default['hadoop']['jobtracker_port'] = "54311"

# Provide rack info
default['hadoop']['rackaware']['datacenter'] = "default"
default['hadoop']['rackaware']['rack']       = "rack0"

# Use an alternate yum repo and key
default['hadoop']['yum_repo_url']     = nil
default['hadoop']['yum_repo_key_url'] = nil

default['hadoop']['core_site']['hadoop.tmp.dir'] = "/tmp/hadoop-hdfs"

default['hadoop']['hdfs_site']['dfs.name.dir'] = "#{node['hadoop']['core_site']['hadoop.tmp.dir']}/dfs/name"
default['hadoop']['hdfs_site']['dfs.data.dir'] = "#{node['hadoop']['core_site']['hadoop.tmp.dir']}/dfs/data"

default['hadoop']['mapred_site']['mapred.fairscheduler.allocation.file'] = "#{node['hadoop']['conf_dir']}/fair-scheduler.xml"

default['zookeeper']['dataDir'] = "/var/zookeeper"
default['zookeeper']['dataLogDir'] = "#{node['zookeeper']['dataDir']}"
default['zookeeper']['clientPort'] = "2181"

# log4j default values are defined in the log4j properties files

case node['platform']
when "redhat", "centos", "scientific", "fedora"
  # TODO This needs to actually use the gpg keys... derp.

  if node['hadoop']['yum_repo_url']
    yum_repo_url = node['hadoop']['yum_repo_url']
  else
    platform_major_version = node['platform_version'].to_i

    case platform_major_version
    when 5
      yum_repo_url = "http://archive.cloudera.com/redhat/cdh/#{node['hadoop']['release']}"
    when 6
      yum_repo_url = "http://archive.cloudera.com/redhat/6/x86_64/cdh/#{node['hadoop']['release']}"
    end
  end

  Chef::Log.info "Adding yum repository #{yum_repo_url}"
  yum_repository "cloudera-cdh#{node['hadoop']['release']}" do
    name "cloudera-cdh3"
    description "Cloudera's Hadoop"
    url yum_repo_url
    action :add
  end
when "debian", "ubuntu"
  cdh_version = node['hadoop']['release']
  os_dist = node['lsb']['id'].downcase
  os_version = node['lsb']['codename']
  os_arch = node['kernel']['machine']
  os_arch = 'amd64' if os_arch == 'x86_64'

  if cdh_version[0..0] == '3'
    # deb http://archive.cloudera.com/debian <RELEASE>-cdh3 contrib
    apt_repo_uri = "http://archive.cloudera.com/debian"
    apt_dist = "#{os_version}-cdh#{cdh_version}"
    apt_key = "http://archive.cloudera.com/debian/archive.key"
  else
    # deb [arch=amd64] http://archive.cloudera.com/cdh4/<OS-release-arch> <RELEASE>-cdh4 contrib
    apt_repo_uri ="[arch=amd64] http://archive.cloudera.com/cdh4/#{os_dist}/#{os_version}/#{os_arch}/cdh"
    apt_dist = "#{os_version}-cdh4"
    apt_key = "http://archive.cloudera.com/cdh4/#{os_dist}/#{os_version}/#{os_arch}/cdh/archive.key"
  end
  Chef::Log.info "Adding apt repository #{apt_repo_uri} #{apt_dist} contrib"
  apt_repository "cloudera-cdh#{cdh_version}" do
    uri apt_repo_uri
    distribution apt_dist
    components [ "contrib" ]
    key apt_key
    deb_src true
  end

  # we're forcing apt-get update manually for now, due to http://tickets.opscode.com/browse/COOK-1385
  execute "apt-get update" do
    user    "root"
    group   "root"
    command "apt-get update"
    ignore_failure true
  end
end

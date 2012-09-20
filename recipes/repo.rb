include_recipe "cloudera::default"

case node[:platform]
when "redhat", "centos", "scientific", "fedora"
  # TODO This needs to actually use the gpg keys... derp.

  if node[:hadoop][:yum_repo_url]
    yum_repo_url = node[:hadoop][:yum_repo_url]
  else
    platform_major_version = node[:platform_version].to_i

    case platform_major_version
    when 5
      yum_repo_url = "http://archive.cloudera.com/redhat/cdh/#{node[:hadoop][:release]}"
    when 6
      yum_repo_url = "http://archive.cloudera.com/redhat/6/x86_64/cdh/#{node[:hadoop][:release]}"
    end
  end

  yum_repository "cloudera-cdh#{node[:hadoop][:release]}" do
    name "cloudera-cdh3"
    description "Cloudera's Hadoop"
    url yum_repo_url
    action :add
  end
when "debian", "ubuntu"
  cdh_version = node[:hadoop][:release]
  os_dist = node['lsb']['id'].downcase
  os_version = node['lsb']['codename']
  os_arch = node['kernel']['machine']
  os_arch = 'amd64' if os_arch == 'x86_64'

  case node[:hadoop][:release][0]
  when '3'
    # deb http://archive.cloudera.com/debian <RELEASE>-cdh3 contrib
    apt_repository "cloudera-cdh#{cdh_version}" do
      uri "http://archive.cloudera.com/debian"
      distribution "#{os_version}-cdh#{cdh_version}"
      components [ "contrib" ]
      key "http://archive.cloudera.com/debian/archive.key"
    end
  when '4'
    # deb http://archive.cloudera.com/cdh4/<OS-release-arch> <RELEASE>-cdh4 contrib
    apt_repository "cloudera-cdh#{cdh_version}" do
      uri "http://archive.cloudera.com/cdh4/#{os_dist}/#{os_version}/#{os_arch}/cdh"
      distribution "#{os_version}-cdh#{cdh_version}"
      components [ "contrib" ]
      key "http://archive.cloudera.com/cdh4/#{os_dist}/#{os_version}/#{os_arch}/cdh/archive.key"
    end
  end
end

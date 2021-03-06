#
# Cookbook Name:: apache
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#keep info up-to-date
if node["platform"] == "ubuntu"
		execute "apt-get update -y" do
		end
end

# package "apache2" is just naming the package
package "apache2" do
				package_name node["apache"]["package"]
end

node["apache"]["sites"].each do |sitename, data|

	if node["platform"] == "ubuntu"
			document_root = "/var/www/html/#{sitename}"
			template_vhost_location = "/etc/apache2/sites-enabled/#{sitename}.conf"
			template_index_location = "/var/www/html/#{sitename}/index.html"
	elsif node["platform"] == "centos"
			document_root = "/content/sites/#{sitename}"
			template_vhost_location = "/etc/httpd/conf.d/#{sitename}.conf"
			template_index_location = "/content/sites/#{sitename}/index.html"
	end

  directory document_root do
		mode "0755"
		recursive true
  end

  template template_vhost_location do
		source "vhost.erb"
		mode "0755"
		variables(
			:document_root => document_root,
			:port => data["port"],
			:domain => data["domain"]
			)
			notifies :restart, "service[httpd]"
  end
# Ubuntu only allows content on /var/www/html
	template template_index_location do
		source "index.html.erb"
		mode "0644"
		variables(
			:site_title => data["site_title"],
			:comingsoon => "Coming Soon!",
			:author_name => node["author"]["name"]
		)
	end
end

execute "rm /etc/httpd/conf.d/welcome.conf" do
	only_if do
				File.exist?("/etc/httpd/conf.d/welcome.conf")
	end
	notifies :restart, "service[httpd]"
end
execute "rm /etc/httpd/conf.d/README" do
	only_if do
				File.exist?("/etc/httpd/conf.d/README")
	end
	notifies :restart, "service[httpd]"
end

#when you define service_name, it takes service_name value.
#Otherwise it takes the value define in service ""
service "httpd" do
	service_name node["apache"]["package"]
	action [:enable, :start]

end

include_recipe "php::default"

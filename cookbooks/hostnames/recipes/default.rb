template "/etc/hosts" do
	source "hosts.erb"
end

template "/etc/hostname" do
	source "hostname.erb"
end

execute "fixhostname" do
	command "hostname " + node["self"][:name]
end

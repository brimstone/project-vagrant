# -*- mode: ruby -*-
# vi: set ft=ruby :

require("json")

host = JSON.load File.new(File.expand_path("../host.json", __FILE__))
boxes = JSON.load File.new(File.expand_path("../boxes.json", __FILE__))
default = boxes["default"]
boxes.delete("default")

# TODO: Support a "Base" config
# TODO: Push this file to a different repo?
# http://dustinrcollins.com/post/61277870546/multi-vm-vagrant-the-dry-way
Vagrant.configure("2") do |box|
	boxes.keys.each do |optskey|
		opts = default.clone()
		boxes[optskey].keys.each do |key|
			opts[key] = boxes[optskey][key]
		end
		# something should be done here to preserve the old box hash, to be added back later.
		boxes.delete(optskey)

		$hosts = "cat <<DOG > /etc/hosts\n127.0.0.1	localhost " + optskey + "\n"
		boxes.keys.each do |hostname|
			$hosts += boxes[hostname]["ip"] + "\t" + hostname + "\n"
		end
		$hosts += "DOG\n"

		$hosts += "echo " + optskey + " > /etc/hostname; hostname " + optskey

		box.vm.define optskey do |config|
			# which box to use as a base
			unless opts["box"].nil?
				config.vm.box = opts["box"]
				unless opts["url"].nil?
					config.vm.box_url = opts["url"]
				end
			else
				config.vm.box = "ubuntu-12.04-amd64"
			end
	
			# Create a forwarded port mapping which allows access to a specific port
			# within the machine from a port on the host machine. In the example below,
			# accessing "localhost:8080" will access port 80 on the guest machine.
			# config.vm.network :forwarded_port, guest: 80, host: 8080
	
			# Create a private network, which allows host-only access to the machine
			# using a specific IP.
			unless opts["ip"].nil?
				config.vm.network :private_network, ip: opts["ip"], virtuabox__intnet: true
			end
	
			# Create a public network, which generally matched to bridged network.
			# Bridged networks make the machine appear as another physical device on
			# your network.
			# config.vm.network :public_network
		
			# Share an additional folder to the guest VM. The first argument is
			# the path on the host to the actual folder. The second argument is
			# the path on the guest to mount the folder. And the optional third
			# argument is a set of non-required options.
			# config.vm.synced_folder "../data", "/vagrant_data"
			# Synced folders
			unless opts["synced_folders"].nil?
				opts["synced_folders"].each do |hash|
					hash.each do |folder1, folder2|
						config.vm.synced_folder folder1, folder2
					end
				end
			end
		
			# Provider-specific configuration so you can fine-tune various
			# backing providers for Vagrant. These expose provider-specific options.
			# Example for VirtualBox:
			#
			# config.vm.provider :virtualbox do |vb|
			#	# Don't boot with headless mode
			#	vb.gui = true
			#
			#	# Use VBoxManage to customize the VM. For example to change memory:
			#	vb.customize ["modifyvm", :id, "--memory", "1024"]
			# end
			# VirtualBox customizations
			unless host["ip"].nil?
				config.vm.provider :virtualbox do |vb|
					vb.customize ["hostonlyif", "ipconfig", "vboxnet0", "--ip", host["ip"]]
				end
			end

			unless opts["vbox_config"].nil?
				config.vm.provider :virtualbox do |vb|
					opts["vbox_config"].each do |hash|
						hash.each do |key, value|
							vb.customize ['modifyvm', :id, key, value]
						end
					end
				end
			end

			config.vm.provision "shell", inline: $hosts
			# Run shell commands for box
			unless opts["commands"].nil?
				opts["commands"].each do |command|
					config.vm.provider :virtualbox do |vb|
						config.vm.provision :shell, inline: command
					end
				end
			end
			# Enable provisioning with chef solo, specifying a cookbooks path, roles
			# path, and data_bags path (all relative to this Vagrantfile), and adding
			# some recipes and/or roles.
			#
			unless opts["recipes"].nil? and opts["role"].nil?
				config.vm.provision :chef_solo do |chef|
					chef.cookbooks_path = "cookbooks"
					chef.roles_path = "roles"
					chef.data_bags_path = "data_bags"
					unless opts["recipes"].nil?
						opts["recipes"].each do |recipe|
							chef.add_recipe recipe
						end
					end
				#	chef.add_role "web"
					# Add a Chef role if specified
					unless opts["role"].nil?
						chef.add_role(opts["role"])
					end
				#
				#	# You may also specify custom JSON attributes:
				#	chef.json = { :mysql_password => "foo" }
				chef.json = { :boxes => boxes, :self => opts, :host => host }
				end
			end
		end
		boxes[optskey] = opts
	end
end

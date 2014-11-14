# -*- mode: ruby -*-
# vi: set ft=ruby :

require('json')

basepath = File.expand_path('../', __FILE__)

host = JSON.load File.new("#{basepath}/host.json")
boxes = JSON.load File.new("#{basepath}/boxes.json")
default = boxes['default']
boxes.delete('default')
host['domain'] = 'local' if host['domain'].nil?

Dir.glob("#{basepath}/nodes/*.json").each do |nodefile|
  node = JSON.load File.new(nodefile)
  boxes[node['id']] = node
end

# TODO: Support a "Base" config
# TODO: Push this file to a different repo?
# http://dustinrcollins.com/post/61277870546/multi-vm-vagrant-the-dry-way
Vagrant.configure('2') do |box|
  boxes.keys.each do |optskey|
    opts = default.clone
    boxes[optskey].keys.each do |key|
      opts[key] = boxes[optskey][key]
    end
    # something should be done here to preserve the old box hash, to be added back later.
    boxes.delete(optskey)

    hosts =  "cat <<DOG > /etc/hosts\n"
    hosts += "127.0.0.1\tlocalhost.localdomain localhost\n"
    hosts += "127.0.1.1\t" + optskey + '.' + host['domain'] + ' ' + optskey + "\n"
    boxes.keys.each do |hostname|
      unless boxes[hostname]['ip'].nil?
        hosts += boxes[hostname]['ip'] + "\t" + hostname + '.' + host['domain'] + ' ' + hostname + "\n"
      end
    end
    hosts += "DOG\n"

    # TODO Debug this over config.vm.hostname
    hosts += 'echo ' + optskey + ' > /etc/hostname; hostname ' + optskey

    box.vm.define optskey do |config|
      # which box to use as a base
      unless opts['box'].nil?
        config.vm.box = opts['box']
        unless opts['url'].nil?
          config.vm.box_url = opts['url']
        end
      else
        config.vm.box = 'ubuntu-12.04-amd64'
      end

      # Set our hostname properly
      config.vm.hostname = optskey

      # Create a forwarded port mapping which allows access to a specific port
      # within the machine from a port on the host machine. In the example below,
      # accessing "localhost:8080" will access port 80 on the guest machine.
      unless opts['ports'].nil?
        opts['ports'].each do |hash|
          hash.each do |host, guest|
            config.vm.network :forwarded_port, guest: Integer(guest), host: Integer(host)
          end
        end
      end

      # Create a private network, which allows host-only access to the machine
      # using a specific IP.
      unless opts['ip'].nil?
        config.vm.network :private_network, ip: opts['ip']
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
      unless opts['synced_folders'].nil?
        opts['synced_folders'].each do |hash|
          hash.each do |folder1, folder2|
            config.vm.synced_folder folder1, folder2
          end
        end
      end

      # Provider-specific configuration so you can fine-tune various
      # backing providers for Vagrant. These expose provider-specific options.
      # Example for VirtualBox:
      #
      config.vm.provider :virtualbox do |vb|
        #	# Don't boot with headless mode
        #	vb.gui = true
        #
        #	# Use VBoxManage to customize the VM. For example to change memory:
        unless opts['memory'].nil?
          vb.customize ['modifyvm', :id, '--memory', opts['memory']]
        end
      end
      # VirtualBox customizations
      unless host['ip'].nil?
        config.vm.provider :virtualbox do |vb|
          vb.customize ['hostonlyif', 'ipconfig', 'vboxnet0', '--ip', host['ip']]
        end
      end

      unless opts['vbox_config'].nil?
        config.vm.provider :virtualbox do |vb|
          opts['vbox_config'].each do |hash|
            hash.each do |key, value|
              vb.customize ['modifyvm', :id, key, value]
            end
          end
        end
      end

      config.vm.provision 'shell', inline: hosts
      # Run shell commands for box
      unless opts['commands'].nil?
        opts['commands'].each do |command|
          config.vm.provision :shell, inline: command
        end
      end
      # Enable provisioning with chef solo, specifying a cookbooks path, roles
      # path, and data_bags path (all relative to this Vagrantfile), and adding
      # some recipes and/or roles.
      #
      unless opts['recipes'].nil? && opts['roles'].nil?
        if Vagrant.has_plugin?('vagrant-chef-zero')
          config.chef_zero.chef_repo_path = basepath
          # config.chef_zero.cookbooks = "#{basepath}/cookbooks"
          # config.chef_zero.data_bags = "#{basepath}/data_bags"
          config.chef_zero.nodes = "#{basepath}/chef_nodes"
          config.vm.provision :chef_client do |chef|
            unless opts['environment'].nil?
              chef.environment = opts['environment']
            end
            unless opts['recipes'].nil?
              opts['recipes'].each do |recipe|
                chef.add_recipe recipe
              end
            end
            unless opts['roles'].nil?
              opts['roles'].each do |role|
                chef.add_role role
              end
            end
            unless opts['attributes'].nil?
              chef.json = chef.json.merge(opts['attributes'])
            end
          end
        else
          config.vm.provision :chef_solo do |chef|
            # chef.log_level = :debug
            chef.cookbooks_path = 'cookbooks'
            chef.roles_path = "#{basepath}/roles" if File.exist? 'roles'
            chef.data_bags_path = '.'
            chef.environments_path = "#{basepath}/environments" if File.exist? "#{basepath}/environments"
            unless opts['environment'].nil?
              chef.environment = opts['environment']
            end
            unless opts['recipes'].nil?
              opts['recipes'].each do |recipe|
                chef.add_recipe recipe
              end
            end
            #	chef.add_role "web"
            # Add a Chef role if specified
            unless opts['roles'].nil?
              opts['roles'].each do |role|
                chef.add_role role
              end
            end
            #
            #	# You may also specify custom JSON attributes:
            #	chef.json = { :mysql_password => "foo" }
            chef.json = { boxes: boxes, self: opts, host: host, location: 'vagrant' }
            unless opts['attributes'].nil?
              chef.json = chef.json.merge(opts['attributes'])
            end
          end
        end
      end
    end
    boxes[optskey] = opts
  end
end

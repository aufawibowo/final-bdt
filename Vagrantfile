# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

Vagrant.configure("2") do |config|
  config.vm.define "server190" do |node|
    node.vm.hostname = "server190"
    node.vm.box = "bento/ubuntu-18.04"
    node.vm.network "private_network", ip: "192.168.16.190"
    
    node.vm.provider "virtualbox" do |vb|
      vb.name = "server190"
      vb.gui = false
      vb.memory = "1024"
    end
    #node.vm.provision "shell", path: "provision/server190.sh", privileged: false
  end

  config.vm.define "server191" do |node|
    node.vm.hostname = "server191"
    node.vm.box = "bento/ubuntu-18.04"
    node.vm.network "private_network", ip: "192.168.16.191"
    
    node.vm.provider "virtualbox" do |vb|
      vb.name = "server191"
      vb.gui = false
      vb.memory = "1024"
    end
  end


  (4..9).each do |i|
    config.vm.define "server18#{i}" do |node|
      node.vm.hostname = "server18#{i}"
      node.vm.box = "bento/ubuntu-18.04"
      node.vm.network "private_network", ip: "192.168.16.18#{i}"
      
      node.vm.provider "virtualbox" do |vb|
        vb.name = "server18#{i}"
        vb.gui = false
        vb.memory = "1024"
      end
      #node.vm.provision "shell", path: "provision/bootstrap184-186.sh", privileged: false

    end
  end

end


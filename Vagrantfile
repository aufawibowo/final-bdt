# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

Vagrant.configure("2") do |config|
  
  (4..9).each do |i|
    config.vm.define "server18#{i}" do |node|
      node.vm.hostname = "server18#{i}"
      node.vm.box = "bento/ubuntu-18.04"
      node.vm.network "private_network", ip: "192.168.16.18#{i}"
      
      node.vm.provider "virtualbox" do |vb|
        vb.name = "server18#{i}"
        vb.gui = false
        vb.memory = "512"
      end
  
    end
  end

  (1..2).each do |i|
    config.vm.define "server19#{i-1}" do |node|
      node.vm.hostname = "server19#{i-1}"
      node.vm.box = "bento/ubuntu-18.04"
      node.vm.network "private_network", ip: "192.168.16.19#{i-1}"
      
      node.vm.provider "virtualbox" do |vb|
        vb.name = "server19#{i-1}"
        vb.gui = false
        vb.memory = "512"
      end
  
    end
  end


end


# encoding: utf-8
# This file originally created at http://rove.io/5d79e605e617fdf02f19efd193a26a04

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "opscode-ubuntu-14.10"
  config.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.10_chef-provisionerless.box"
  config.omnibus.chef_version = :latest
  config.ssh.forward_agent = true
  config.vm.network :forwarded_port, host: 3000, guest: 3000

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ["cookbooks", "custom-cookbook"]
    chef.add_recipe :apt
    chef.add_recipe 'vim'
    chef.add_recipe 'git'
    chef.add_recipe 'ruby_build'
    chef.add_recipe 'nodejs'
    chef.add_recipe 'clash_app'

    chef.json = {
      :vim        => {
        :extra_packages => [
          "vim-rails"
        ]
      },
      :git        => {
        :prefix => "/usr/local"
      },
    }
  end
end


VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  
  config.vm.box = "bfair"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.hostname = "bfair.local"  
  config.vm.network :private_network, ip: "192.168.33.10"

  
  config.vm.provision :shell, :path => "shell/puppet.sh"
  config.vm.provision :shell, :path => "shell/hiera.sh"
   
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path 		= "puppet/manifests"
    puppet.manifest_file 		= "bfair.pp"
	puppet.module_path 			= "puppet/modules"
	puppet.options				= "--verbose --hiera_config /vagrant/puppet/hiera.yaml"
	
	puppet.facter = {
        "environment" => "development",
        "vm_type"     => "vagrant",
      }
	
  end

end

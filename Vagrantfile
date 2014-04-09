
require 'yaml'
vconfig = YAML::load_file(File.join(__dir__, 'vagrantconfig.yml'))
puts "Using Config file: " + File.join(__dir__, 'vagrantconfig.yml')

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  
  config.vm.box = "bfair"
  if vconfig['uselocalbox']
  	config.vm.box_url = "file://" + vconfig['boxpath'] + "precise64.box"  
  else
  	config.vm.box.url = "http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210.box"
  end
  config.vm.hostname = "bfair.local"  
  config.vm.network :private_network, ip: "192.168.33.10"
  
  
  # Virtual Box Provider Configuration
  config.vm.provider "virtualbox" do |v|
	  v.memory = 6256
	  v.name = 'bfair'
	  v.cpus = 2
	  # v.gui = true
	end

  if vconfig['aws']
  	  # Begin the AWS Provider Configuration:
	  config.vm.provider :aws do |aws,override|
	    aws.access_key_id = vconfig['accesskey']
	    aws.secret_access_key = vconfig['secretkey']
	    aws.keypair_name = "bfairkeys"
	    aws.region = "eu-west-1"
	
	    aws.ami = "ami-ff68f8cf" # Ubuntu 12.04LTS in us-west-2"
	
	    override.ssh.username = "ubuntu"
	    override.ssh.private_key_path = "PATH TO YOUR PRIVATE KEY"
	  end
	
	  # This box will be brought up in EC2
	  config.vm.define :web_aws do |web|
	    web.vm.box = "dummy"
	    web.vm.hostname = "www.kloudless.aws" # Dummy hostname
	  end	
  	end
  

  # Symlink for hiera.yaml
  config.vm.provision :shell, :path => "scripts/hiera.sh"
  
 # Puppet 
  	config.vm.provision :puppet do |puppet|
    puppet.manifests_path 		= "puppet/manifests"
    puppet.manifest_file 		= "bfair.pp"
	puppet.module_path 			= "puppet/modules"
	puppet.options				= "--verbose --logdest=/var/log/puppet_apply.log --logdest=console"
	puppet.facter = {
        "environment" => "development",
        "vm_type"     => "vagrant",
      }	
  end

end

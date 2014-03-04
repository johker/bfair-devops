

node 'bfair' { 

  # Node Installation 
  include nodejs
  
  # Checkout Bfair Sources 
  import 'clone.pp'
  
  # RabbitMQ Installation including Management Console  
  class { 'rabbitmq':
    port           => '5672',
    service_manage => true,
    admin_enable   => true,
  }

  # MongoDB Installation
  class { '::mongodb::server':
    port    => 27018,
    verbose => true,
  }
  
  
  # make sure directory exists
	file { "/usr/local/bin":
	    ensure => "directory"
	} 
	
	 
  
  # Wrapper Script for Puppet Apply Command
  file { '/usr/local/bin/papply':
      mode => 777,
      content => "#!/bin/sh\n sudo puppet apply /vagrant/puppet/manifests/site.pp --modulepath=/vagrant/puppet/modules $*",
  }  
  


 
 
 
}



node 'bfair' { 

  # make sure directory exists
  file { "/usr/local/bin":
      ensure => "directory"
  } 
     
  # Wrapper Script for Puppet Apply Command
  notice('Wrapping Puppet Apply command')
  file { '/usr/local/bin/papply':
      mode => 777,
      content => "#!/bin/sh\n sudo puppet apply /vagrant/puppet/manifests/site.pp --modulepath=/vagrant/puppet/modules $*",
  } 

  # Node Installation 
  notice('Node js installation')
  include nodejs
  
  # Maven Installation
  notice('Maven installation')
  import 'maven.pp'
  
  # Checkout Bfair Sources
  notice('Bfair source checkout') 
  import 'clone.pp'

  class { 'bfair_checkout':
    username => 'bfairdev'
  }
  
  # RabbitMQ Installation including Management Console
  notice('RabbitMQ installation')  
  class { 'rabbitmq':
    port           => '5672',
    service_manage => true,
    admin_enable   => true,
  }

  # MongoDB Installation
  notice('MongoDB Installation')
  class { '::mongodb::server':
    port    => 27018,
    verbose => true,
  }
   
  
	    
   
  
  


 
 
 
}



node 'bfair' { 

  # make sure directory exists
  file { "/usr/local/bin":
      ensure => "directory"
  } ->
    
  # Install latest Java   
  class { 'java':
    distribution => 'jdk',
    version      => 'latest',
  } ->
  
  file_line { 'java_home':
   path => '/etc/environment',
   line => 'JAVA_HOME=/usr/lib/jvm/java-7-oracle'
	} 
	          
	# Wrapper Script for Puppet Apply Command 
  file { '/usr/local/bin/papply':
      mode => 777,
      content => "#!/bin/sh\n sudo puppet apply /vagrant/puppet/manifests/site.pp --modulepath=/vagrant/puppet/modules $*",
  } 
  

  # Node Installation 
  notice('Installing  Node.js')
  include nodejs
    
  
	# Maven Installation
  notice('Installing Maven')
	class { maven : }
  
  
  # Checkout Bfair Sources
  notice('Bfair source checkout') 
  import 'clone.pp'

  class { 'bfair_checkout':
    username => 'bfairdev'
  }
  
  
  # RabbitMQ Installation including Management Console
  notice('Installing RabbitMQ')  
  class { 'rabbitmq':
    port           => '5672',
    service_manage => true,
    admin_enable   => true,
  }


  # MongoDB Installation
  notice('Installing MongoDB ')
  class { '::mongodb::server':
    port    => 27018,
    verbose => true,
  }
  
  # Build and execute bfair_pricing
  import "boot.pp"
	  
}

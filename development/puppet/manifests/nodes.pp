

node 'bfair' { 
  
  $java_home = '/usr/java/jdk1.7.0_51'
  $maven_version = '3.0.5'
  $application_name = 'pricing-0.1.jar'
  $username = 'bfairdev'
  $group = 'bfairdev'
  
  include jdk7
  include nodejs
  
  import 'clone.pp'
  import 'boot.pp'
  import 'variables.pp'
   
   

   
  
	
  # Wrapper Script for Puppet Apply Command 
  file { '/usr/local/bin/papply':
      mode => 777,
      content => "#!/bin/sh\nsudo puppet apply /vagrant/puppet/manifests/site.pp --modulepath=/vagrant/puppet/modules $*",
  } 
    
    
    
   # Install latest Java  
   jdk7::install7 { 'jdk1.7.0_51':
      version              => "7u51" , 
      fullVersion          => "jdk1.7.0_51",
      alternativesPriority => 18000, 
      x64                  => true,
      downloadDir          => "/data/install",
      urandomJavaFix       => true,
      sourcePath           => "/vagrant/software",
  }
          
    
  # Maven Installation 
  class { 'maven::maven' :
    version => $maven_version,
    java_home => $java_home
   }    
	 notify {'Maven has been installed':
      require => Class['maven::maven']
    }
  
  
  # Checkout bfair sources
  class { 'bfair_checkout':
    username => $username,
    group => $group
  }
  notify {'Bfair repositories have been cloned':
      require => Class['bfair_checkout'],
   }
  
  
  # RabbitMQ Installation including Management Console
  class { 'rabbitmq':
    port           => '5672',
    service_manage => true,
    admin_enable   => true,
  }
  notify {'RabbitMQ has been installed':
      require => Class['rabbitmq'],
   }
  

  # MongoDB Installation
  class { '::mongodb::server':
    port    => 27018,
    verbose => true,
  }
  notify {'MongoDB has been installed':
      require => Class['::mongodb::server'],
   }


  # Setting home varaibles
  class { 'home_variables':
      java_home => $java_home, 
      maven_version => $maven_version 
  }

  
  # Build and execute bfair_pricing
  class { 'spring_boot':
    application_name => $application_name,
    username => $username,
    group => $group,
    java_home => $java_home
  }
	  
}

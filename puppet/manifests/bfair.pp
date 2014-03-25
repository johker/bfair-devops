

node 'bfair.local' { 
  
  include os
  include clone
  include pricing
  include bfnode
 
  Class['os']  -> 
    Class['clone']  ->
      Class['pricing'] -> 
        Class['bfnode']
  }
  
  
class os {
		  notice 'class os'
		  
      include jdk7

      $user             = hiera('bf_os_user')
      $group            = hiera('bf_os_group')
      $maven_version    = hiera('bf_mvn_version')
      $java_home        = hiera('bf_java_home_dir')
		  
		  # Wrapper Script for Puppet Apply Command 
		  file { '/usr/local/bin/papply':
		      mode => 777,
		      content => "#!/bin/sh\nsudo puppet apply /vagrant/puppet/manifests/bfair.pp --hiera_config /vagrant/puppet/hiera.yaml --modulepath=/vagrant/puppet/modules $*",
		  } 
		  
	    # Java Installation
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
}
  
  

class clone {
		  notice 'class clone'
		  
      $user   = hiera('bf_os_user')
      $group  = hiera('bf_os_group')
      
		  group { $user:
		    ensure => present,
		    gid    => 2000,
		  }
		
		  user { $user:
		    ensure     => present,
		    gid        => $group,
		    require    => Group[$group],
		    password => sha1('hello'),
		    uid        => 2000,
		    home       => "/home/${user}",
		    shell      => "/bin/bash",
		    managehome => true,
		  }
		
		  file { '/opt/code':
		    ensure => directory,
		    group  => $group,
		    owner  => $user,
		    mode   => 777,
		  }
		
		  file { '/home/${user}':
		    ensure => directory,
		    group  => $group,
		    owner  => $user,
		    mode   => 0700,
		  }
		
		  package { 'git': ensure => installed, }
		
		  vcsrepo { "/opt/code/bfair":
		    ensure   => latest,
		    owner    => $user,
		    group    => $group,
		    provider => git,
		    require  => [Package["git"]],
		    source   => "https://github.com/johker/bfair.git",
		    revision => 'master',
		  }
		
		  vcsrepo { "/opt/code/bfair_pricing":
		    ensure   => latest,
		    owner    => $user,
		    group    => $group,
		    provider => git,
		    require  => [Package["git"]],
		    source   => "https://github.com/johker/bfair_pricing.git",
		    revision => 'master',
		  }
}
  
  
class pricing {
      notice 'class pricing'
      
      include java_service_wrapper
      
      $user               = hiera('bf_os_user')
      $group              = hiera('bf_os_group')
      $maven_version      = hiera('bf_mvn_version')
      $java_home          = hiera('bf_java_home_dir')
      $application_name   = hiera('bf_app_name')
      
		  # Make sure target directory exists
		  file { "/opt/code/bfair_pricing/target":
		      ensure => "directory",
		      owner => $user, 
		      group => $group,
		      mode => "0755",
		   } 
		  
		  # Maven package
		  exec { "maven_build":
		    command => "mvn package -f /opt/code/bfair_pricing/pom.xml",
		    user    => $user, 
		    group   => $group,
		    path    => "${path}"
		  }     
		    
		  file { "/var/log/bfairpricing":
		    ensure => "directory",
		    owner => $user, 
		    group => $group,
		    mode => "0755",
		  } 
		    
		  # Run pricing jar as service
		  java_service_wrapper::service{ 'bfairpricing':
		      run_as_user        => 'root',
		      wrapper_java_cmd   => "${java_home}/bin/java", 
		      wrapper_mainclass  => 'WrapperJarApp',
		      wrapper_additional => ['-Xms1G', '-Xmx1G'],
		      wrapper_library    => ['/usr/local/lib'],
		      wrapper_classpath  => ['/usr/local/lib/wrapper.jar', "/opt/code/bfair_pricing/target/${application_name}"],
		      wrapper_parameter  => ["/opt/code/bfair_pricing/target/${application_name}"]
		  }
   
}
   
 class bfnode {
   
   notice 'class bfnode'
   
   include nodejs
  
    
   
 }
   
  

	




node 'bfair.local' { 
  
  contain os
  contain clone
  contain pricing
  contain bfnode
  contain db
 
 
	 # $PATH for all exec 
	 # http://www.puppetcookbook.com/posts/set-global-exec-path.html 
	Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin/" ] }
	 
 
	  Class['os']  -> 
	    Class['clone']  ->
	      Class['pricing'] -> 
	        Class['bfnode'] ->
	         Class['db']
  }
  
class os {
		  notice 'class os'
		  
      contain jdk7

      $user             = hiera('bf_os_user')
      $group            = hiera('bf_os_group')
      $maven_version    = hiera('bf_mvn_version')
      $java_home        = hiera('bf_java_home_dir')
      
		  
		  file { "/opt/env.sh":
		    mode => 777,
		    content => "export JAVA_HOME=${java_home}\nexport PATH=\$PATH:\$JAVA_HOME/bin\nexport M2_HOME=/opt/apache-maven-${maven_version}\nexport M2=%M2_HOME%/bin"
	    } ->
	    
		  exec { "set_variables": 
		    command => "/bin/bash /opt/env.sh",
		    logoutput => true,
		  } ->
		  
		  # Wrapper Script for Puppet Apply Command 
		  file { '/usr/local/bin/papply':
		      mode => 777,
		      content => "#!/bin/sh\nsudo puppet apply /vagrant/puppet/manifests/bfair.pp --hiera_config=/vagrant/puppet/hiera.yaml --profile --logdest=/var/log/puppet_apply.log --logdest=console --modulepath=/vagrant/puppet/modules --graph $*",
		  } 
		  
		  # Set User and Group
		  group { $group:
        ensure => present,
        gid    => 2000,
      }
    
      user { $user:
        ensure     => present,
        gid        => $group,
        require    => Group[$group],
        password => sha1('bfair'),
        uid        => 2000,
        home       => "/home/${user}",
        shell      => "/bin/bash",
        managehome => true,
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

		  # RabbitMQ Installation including Management Console
		  class { 'rabbitmq':
			  port          => '5672',
			  admin_enable  => true,
			  
			}
		  
		  
        
     
}
  
  

class clone {
		  notice 'class clone'
		  
      $user   = hiera('bf_os_user')
      $group  = hiera('bf_os_group')
      
		  		
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
      
      contain java_service_wrapper
      
      $user               = hiera('bf_os_user')
      $group              = hiera('bf_os_group')
      $maven_version      = hiera('bf_mvn_version')
      $java_home          = hiera('bf_java_home_dir')
      $application_name   = hiera('bf_app_name')
     
            
      # Maven Installation 
      class { 'maven::maven' :
        version => $maven_version,
        java_home => $java_home
       }    
      
		  # Make sure target directory exists
		  file { "/opt/code/bfair_pricing/target":
		      ensure => "directory",
		      recurse => true, 
          purge   => true, 
		      owner => $user, 
		      group => $group,
		      mode => "0755",
		      require => File['/usr/bin/mvn']
		   }
		   
		  # Maven Build File
      file { '/usr/local/bin/buildpr':
          mode => 777,
          content => "#!/bin/sh\nmvn package -f /opt/code/bfair_pricing/pom.xml",
          require => File['/opt/code/bfair_pricing/target'], 
      } 
		   
		  exec { "build_pricing_app":
        command => "/bin/bash /usr/local/bin/buildpr",
        logoutput => true,
        require => File['/usr/local/bin/buildpr'], 
      } ->
		   
		  # Maven package - direct call: uknown commmand mvn on initial call
#		  exec { "maven_build":
#		    command => "mvn package -f /opt/code/bfair_pricing/pom.xml",
#		    timeout => 100,
#		    user    => $user, 
#		    group   => $group,
#		    cwd    => "/usr/bin",
#		    path    => ["${path}", "/usr/bin"]
#      }  ->  
      
		  file { "/var/log/bfairpricing":
		    ensure => "directory",
		    owner => $user, 
		    group => $group,
		    mode => "0755",
		    require => Exec['build_pricing_app'],
		  } 
		    
		  # Run pricing jar as service
		  java_service_wrapper::service{ 'bfairpricing':
		      run_as_user        => 'root',
		      wrapper_java_cmd   => "${java_home}/bin/java",    
		      wrapper_mainclass  => 'WrapperJarApp',
		      wrapper_additional => ['-Xms1G', '-Xmx1G'],
		      wrapper_library    => ['/usr/local/lib'],
		      wrapper_classpath  => ['/usr/local/lib/wrapper.jar', "/opt/code/bfair_pricing/target/${application_name}"],
		      wrapper_parameter  => ["/opt/code/bfair_pricing/target/${application_name}"],
		      require            => File['/var/log/bfairpricing']
		  }
   
}
   
 class bfnode {
		   notice 'class bfnode'
		   
		   $user            = hiera('bf_os_user')
		   $group           = hiera('bf_os_group')
		   $nodeEnv         = hiera('node_env')
		   $nodeVersion     = hiera('node_version')
		   
		   # Node js install
       class { 'nodejs':
          version     =>  $nodeVersion,
          with_npm    =>  true
        } 
		   
		    # Package Install based on package.json
		    exec { "npm_install":
		        command     => "npm install",
		        cwd         => "/opt/code/bfair",
		        timeout     => 100,
		        user        => root,
		        path        => ["/usr/local/bin/","/usr/local/node/node-v0.10.26/bin"],
		        logoutput   => true,
		        require     => Class['nodejs']
		      
		    }  
		    
#		    # NPM Install File
#      file { '/usr/local/bin/npminst':
#          mode      => 777,
#          content   => "#!/bin/sh\nnpm install",
#          require   => Class['nodejs']
#      } 
#		    
#		  exec { "exec_npm_install":
#	        command      => "/bin/bash /usr/local/bin/npminst",
#	        cwd          => '/opt/code/bfair',
#	        user         => root,
#	        logoutput    => true,
#	        path         => "${path}",
#	        require      => File['/usr/local/bin/npminst'], 
#      } ->
	 
}
   
   
class db {
  
       $user            = hiera('bf_os_user')
       $group           = hiera('bf_os_group')
  
      
          # Chown MongoDB dir
        file { "/data/db":
              ensure  => "directory",
              owner   => $user,
              group   => $group,
              recurse => true, 
              purge   => true, 
              mode    => "0755"
        } #->
        
        
         # MongoDB Installation
        class { '::mongodb::server':
	          port    => 27018,
	          user    => $user,
	          group   => $group,
	          verbose => true
	        }
        
        
        exec { "launch_mongodb":
            command     => "mongod --port 27018",
            timeout => 100,
            user        => $user, 
            group       => $group,
            path        => "${path}",
            logoutput   => true,
            require     => File["/data/db"]
        } # ->
           
        # Enter users
    #    exec { "setup_users":
    #        command       => "node setup_users.js",
    #        environment  =>  "NODE_ENV=development", 
    #        cwd           => "/opt/code/bfair/setup",
    #        user          => $user, 
    #        group         => $group,
    #        path          => "${path}",
    #        logoutput     => true,
    #        require       => [Exec["launch_mongodb"], Exec["npm_install"]]
    #    } 
  
  
}
  

	


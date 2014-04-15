
node 'bfair.local', 'bfair.aws'   {
  
  contain jdk7
  contain java_service_wrapper

  # $PATH for all exec
  # http://www.puppetcookbook.com/posts/set-global-exec-path.html
  Exec {
    path => ["/bin/", "/sbin/", "/usr/bin/", "/usr/sbin/", "/usr/local/bin/"] }

  $user = hiera('bf_os_user')
  $group = hiera('bf_os_group')
  $maven_version = hiera('bf_mvn_version')
  $java_home = hiera('bf_java_home_dir')
  $application_name = hiera('bf_app_name')
  $nodeEnv = hiera('node_env')
  $nodeVersion = hiera('node_version')
  
  notify { "FQDN = ${fqdn}": 
    
  } ->
  
  file { "/opt/env.sh":
    mode    => 777,
    content => "export JAVA_HOME=${java_home}\nexport PATH=\$PATH:\$JAVA_HOME/bin\n"
  } ->
  exec { "set_variables":
    command   => "/bin/bash /opt/env.sh",
    logoutput => true,
  } ->
  
  # Wrapper Script for Puppet Apply Command
  file { '/usr/local/bin/papply':
    mode    => 777,
    content => "#!/bin/sh\nsudo puppet apply /vagrant/puppet/manifests/bfair.pp --hiera_config=/vagrant/puppet/hiera.yaml --profile --logdest=/var/log/puppet_apply.log --logdest=console --modulepath=/vagrant/puppet/modules --graph $*",
  } ->
  
  # Set User and Group
  group { $group:
    ensure => present,
    gid    => 2000,
  } ->
  
  user { $user:
    ensure     => present,
    gid        => $group,
    require    => Group[$group],
    password   => sha1('bfair'),
    uid        => 2000,
    home       => "/home/${user}",
    shell      => "/bin/bash",
    managehome => true,
  } ->
  
  # Java Installation
  jdk7::install7 { 'jdk1.7.0_51':
    version              => "7u51",
    fullVersion          => "jdk1.7.0_51",
    alternativesPriority => 18000,
    x64                  => true,
    downloadDir          => "/data/install",
    urandomJavaFix       => true,
    sourcePath           => "/vagrant/software",
  } ->
  
  file { '/opt/code':
    ensure => directory,
    group  => $group,
    owner  => $user,
    mode   => 777,
  } ->
  file { '/home/${user}':
    ensure => directory,
    group  => $group,
    owner  => $user,
    mode   => 0700,
  } ->
  package { 'git': ensure => installed, } ->
  vcsrepo { "/opt/code/bfair":
    ensure   => latest,
    owner    => $user,
    group    => $group,
    provider => git,
    require  => [Package["git"]],
    source   => "https://github.com/johker/bfair.git",
    revision => 'master',
  } ->
  
  # Package Install based on package.json
  exec { "npm_install":
      command   => "npm install",
      cwd       => "/opt/code/bfair",
      user      => root,
      path      => "${path}",
      logoutput => true,
   } ->
    
  vcsrepo { "/opt/code/bfair_pricing":
    ensure   => latest,
    owner    => $user,
    group    => $group,
    provider => git,
    require  => [Package["git"]],
    source   => "https://github.com/johker/bfair_pricing.git",
    revision => 'master',
  } ->
  package { 'curl': ensure => present } ->
  
  # RabbitMQ Installation including Management Console
  class { 'rabbitmq':
    port         => '5672',
    admin_enable => true,
  } ->
  
  notify { "PATH = ${path}": 
    
  } ->
  
  # Make sure target directory exists
  file { "/opt/code/bfair_pricing/target":
    ensure  => "directory",
    recurse => true,
    purge   => true,
    owner   => $user,
    group   => $group,
    mode    => "0755",
  } ->
  file { "/var/log/bfairpricing":
    ensure => "directory",
    owner  => $user,
    group  => $group,
    mode   => "0755",
  } ->
  
  # Maven package - direct call: uknown commmand mvn on initial call
    exec { "maven_build":
         command => "mvn package -f /opt/code/bfair_pricing/pom.xml",
         timeout  => 600, 
         user    => $user,
         group   => $group,
         path    => "${path}",
         logoutput => true
   } ->
     
  # Run pricing jar as service
  java_service_wrapper::service { 'bfairpricing':
    run_as_user        => 'root',
    wrapper_java_cmd   => "${java_home}/bin/java",
    wrapper_mainclass  => 'WrapperJarApp',
    wrapper_additional => ['-Xms1G', '-Xmx1G'],
    wrapper_library    => ['/usr/local/lib'],
    wrapper_classpath  => ['/usr/local/lib/wrapper.jar', "/opt/code/bfair_pricing/target/${application_name}"],
    wrapper_parameter  => ["/opt/code/bfair_pricing/target/${application_name}"],
  } ->
 
  # Chown MongoDB dir
  file { "/data/db":
    ensure  => "directory",
    owner   => $user,
    group   => $group,
    recurse => true,
    purge   => true,
    force   => true,
    mode    => "0755"
  } ->
  
  file_line { 'mongodb_rest':
	  path  => '/etc/mongod.conf',
	  line  => 'rest = true',
	  match => 'rest*',
	} ->
	
	file_line { 'mongodb_http':
    path  => '/etc/mongod.conf',
    line  => 'nohttpinterface = false',
    match => 'nohttpinterface*',
  } ->
  
  exec { "launch_mongodb":
    command   => "service mongod restart",
    user      => root,
    path      => "${path}",
    logoutput => true,
  }  ->
  
  # Chown MongoDB dir
  file { "/opt/code/bfair/logs":
    ensure  => "directory",
    owner   => $user,
    group   => $group,
    recurse => true,
    purge   => true,
    mode    => "0755"
  } ->
  
  # Enter users
  exec { "setup_users":
    command       => "node setup_users.js",
    environment  =>  "NODE_ENV=${nodeEnv}",
    cwd           => "/opt/code/bfair/setup",
    user          => $user,
    group         => $group,
    logoutput     => true,          
  } ->
  
  # Enter users
#  exec { "setup_accounts":
#    command       => "node setup_accounts.js",
#    environment  =>  "NODE_ENV=development",
#    cwd           => "/opt/code/bfair/setup",
#    user          => $user,
#    group         => $group,
#    logoutput     => true,          
#  } ->
  
    # Package Install based on package.json
  exec { "npm_install_forever":
      command   => "npm install -g forever",
      user      => root,
      path      => "${path}",
      logoutput => true,
   } -> 
   
   # Enter users
  exec { "start_bfair_core":
    command       => "forever server.js &",
    environment  =>  "NODE_ENV=development",
    cwd           => "/opt/code/bfair",
    user          => root,
    logoutput     => true,          
  } # ->
    
  
}


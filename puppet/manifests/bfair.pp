
node 'bfair.local' {
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

  file { "/opt/env.sh":
    mode    => 777,
    content => "export JAVA_HOME=${java_home}\nexport PATH=\$PATH:\$JAVA_HOME/bin\nexport M2_HOME=/opt/apache-maven-${maven_version}\nexport M2=%M2_HOME%/bin"
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
  # RabbitMQ Installation including Management Console
  #  class { 'rabbitmq':
  #   port                    => '5672',
  #   service_manage          => true,
  #   environment_variables   => {
  #     'RABBITMQ_NODENAME'     => 'server',
  #     'RABBITMQ_SERVICENAME'  => 'rabbitMQ'
  #   }
  # } ->
  #
 
  notify { "PATH = ${path}": } ->
  # Make sure target directory exists
  file { "/opt/code/bfair_pricing/target":
    ensure  => "directory",
    recurse => true,
    purge   => true,
    owner   => $user,
    group   => $group,
    mode    => "0755",
  } ->
  # Maven Build File
#  file { '/usr/local/bin/buildpr':
#    mode    => 777,
#    owner   => $user,
#    group   => $group,
#    content => "#!/bin/sh\nmvn package -f /opt/code/bfair_pricing/pom.xml",
#  } ->
#  exec { "build_pricing_app":
#    command   => "/bin/bash /usr/local/bin/buildpr",
#    logoutput => true,
#  } ->

  file { "/var/log/bfairpricing":
    ensure => "directory",
    owner  => $user,
    group  => $group,
    mode   => "0755",
  } ->
   # Maven Installation
  class { 'maven::maven':
    version   => $maven_version,
    java_home => $java_home
  } ->
  # Maven package - direct call: uknown commmand mvn on initial call
    exec { "maven_build":
         command => "mvn package -f /opt/code/bfair_pricing/pom.xml",
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
  # Node js install
  class { 'nodejs':
    version  => $nodeVersion,
    with_npm => true
  } ->
  # Package Install based on package.json
  #  exec { "npm_install":
  #    command   => "npm install",
  #    cwd       => "/opt/code/bfair",
  #    timeout   => 100,
  #    user      => root,
  #    path      => ["/usr/local/bin/", "/usr/local/node/node-v0.10.26/bin"],
  #    logoutput => true,
  #  } ->
  # NPM Install File
  file { '/usr/local/bin/npminst':
    mode    => 777,
    owner   => $user,
    group   => $group,
    content => "#!/bin/sh\nnpm install\nll",
  } ->
  exec { "exec_npm_install":
    command   => "/bin/bash /usr/local/bin/npminst",
    cwd       => '/opt/code/bfair',
    user      => $user,
    logoutput => true,
    path      => "${path}",
  } ->
  # Chown MongoDB dir
  file { "/data/db":
    ensure  => "directory",
    owner   => $user,
    group   => $group,
    recurse => true,
    purge   => true,
    mode    => "0755"
  } ->
  # MongoDB Installation
  class { '::mongodb::server':
    port    => 27018,
    user    => $user,
    group   => $group,
    verbose => true
  } ->
  exec { "launch_mongodb":
    command   => "mongod --port 27018",
    timeout   => 100,
    user      => $user,
    group     => $group,
    path      => "${path}",
    logoutput => true,
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


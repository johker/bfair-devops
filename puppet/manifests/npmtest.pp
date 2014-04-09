     $user = hiera('bf_os_user')
  $group = hiera('bf_os_group')
    
    
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
    } 
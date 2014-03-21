#
# Cloning core and pricing repositories
#
class bfair_checkout($username, $group) {  
  

  group { $username:
    ensure => present,
    gid    => 2000,
  }

  user { $username:
    ensure     => present,
    gid        => $group,
    require    => Group[$group],
    password => sha1('hello'),
    uid        => 2000,
    home       => "/home/${username}",
    shell      => "/bin/bash",
    managehome => true,
  }

  file { '/opt/code':
    ensure => directory,
    group  => $username,
    owner  => $username,
    mode   => 777,
  }

  file { '/home/${username}':
    ensure => directory,
    group  => $username,
    owner  => $username,
    mode   => 0700,
  }

  package { 'git': ensure => installed, }

  vcsrepo { "/opt/code/bfair":
    ensure   => latest,
    owner    => $username,
    group    => $group,
    provider => git,
    require  => [Package["git"]],
    source   => "https://github.com/johker/bfair.git",
    revision => 'master',
  }

  vcsrepo { "/opt/code/bfair_pricing":
    ensure   => latest,
    owner    => $username,
    group    => $group,
    provider => git,
    require  => [Package["git"]],
    source   => "https://github.com/johker/bfair_pricing.git",
    revision => 'master',
  }
  
  
  
  
}
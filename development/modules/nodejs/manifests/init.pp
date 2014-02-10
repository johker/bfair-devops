class nodejs {
  package { nodejs:
    ensure => installed,
  }
  
  service { nodejs:
    ensure  => running,
    require => Package[nodejs],
  }
  
  file { '/etc/THE_STUFF.conf':
    source => 'puppet:///modules/THE_STUFF/THE_STUFF.conf',
    notify => Service[THE_STUFF],
  }
}
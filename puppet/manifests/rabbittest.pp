# Wrapper Script for Puppet Apply Command 
file { '/usr/local/bin/papply':
          mode => 777,
          content => "#!/bin/sh\nsudo puppet apply /vagrant/puppet/manifests/full.pp --logdest=/var/log/puppet_apply.log --logdest=console --modulepath=/vagrant/puppet/modules --graph $*",
} ->

class { 'rabbitmq':
  port          => '5672',
  admin_enable  => true,
  
}


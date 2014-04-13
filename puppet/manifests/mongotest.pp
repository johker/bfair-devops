 # Wrapper Script for Puppet Apply Command 
file { '/usr/local/bin/papply':
          mode => 777,
          content => "#!/bin/sh\nsudo puppet apply /vagrant/puppet/manifests/mongotest.pp --logdest=/var/log/puppet_apply.log --logdest=console --modulepath=/vagrant/puppet/modules --graph $*",
} ->

notify { "mongotest": 
    
  } ->

 
  # Enter users
      exec { "setup_users":
          command       => "node setup_users.js",
#          environment  =>  "NODE_ENV=development",
          path => '/opt/code/bfair/setup/',
          user          => $user,
          group         => $group,
          logoutput     => true,          
      }
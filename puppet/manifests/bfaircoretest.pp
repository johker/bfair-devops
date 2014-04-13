   # Enter users
  exec { "start_bfair_core":
    command       => "forever server.js &",
    environment  =>  "NODE_ENV=development",
    cwd           => "/opt/code/bfair",
    user          => root,
    path          => "${path}",
    logoutput     => true,          
  }
#
# Building Java standalone jar and launching pricing app
#
class spring_boot($application_name, $username, $group, $java_home) {

 include java_service_wrapper
 
 # TODO: replace imports 
 import 'service.pp'
 

# make sure directory exists
file { "/opt/code/bfair_pricing/target":
    ensure => "directory",
    owner => $username, 
    group => $group,
    mode => "0755",
 } 

  
# Set Maven home on login 
file { "/opt/code/build.sh":
    mode => 777,
    owner => $username, 
    group => $group,
    content => "#!/bin/sh\nrm -r bfair_pricing/target/*\nmvn package -f /opt/code/bfair_pricing/pom.xml"
} 
  
exec { "create_jar":
    command => "/bin/bash /opt/code/build.sh",
    user => $username, 
    logoutput => true,
    require => File['/opt/code/build.sh'] 
}          
  

class { 'pricing_service':
  java_home => $java_home,
  application_name => $application_name,
  require => Exec['create_jar']
}


}

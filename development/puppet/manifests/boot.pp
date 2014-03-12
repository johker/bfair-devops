#
# Building Java standalone jar and launching pricing app
#
class spring_boot($application_name, $username, $group, $java_home) {

 include java_service_wrapper
 
 import 'service.pp'
 



# make sure directory exists
file { "/opt/code/bfair_pricing/target":
    ensure => "directory",
    owner => $username, 
    group => $group,
    mode => "0755",
 } 


#shexecution { 'mvn_package':
#  file => '/opt/code/build.sh', 
#  content => '#!/bin/sh\nrm -fr target/*\nmvn package -f /opt/code/bfair_pricing/pom.xml',
#  user => $username,
#  group => $group
#} 
  

  
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
  
# Java Standalone shortcut for Testing 
file { "/opt/code/startPricing.sh":
    mode => 777,
    owner => $username, 
    group => $group,
    content => "#!/bin/sh\njava -jar bfair_pricing/target/${application_name}",
    require => Exec['create_jar']
} 
  
#exec { "start_pricing":
#    command => "/bin/bash /opt/code/startPricing.sh",
#    user => $username, 
#    logoutput => true,
#    require =>  File['/opt/code/startPricing.sh'] 
#}    
    


class { 'pricing_service':
  java_home => $java_home,
  application_name => $application_name,
  require => Exec['create_jar']
}



#

#java_service_wrapper::service{'logstash':
#  wrapper_mainclass  => 'WrapperJarApp',
#  wrapper_additional => ['-Xms1G', '-Xmx1G'],
#  wrapper_library    => ['/usr/local/lib'],
#  wrapper_classpath  => ['/usr/local/lib/wrapper.jar', '/usr/local/bin/logstash.jar'],
#  wrapper_parameter  => ['/usr/local/bin/logstash.jar', 'agent', '-f', '/etc/logstash/test.conf']
#}


}

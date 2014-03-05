$application_name = 'spring-boot-sample-amqp-1.0.0.BUILD-SNAPSHOT.jar'

# make sure directory exists
file { "/opt/code/bfair_pricing/target":
      ensure => "directory",
      mode => "0755",
      notify => Exec['create_jar']
} 
  
# Maven packaging of standalone jar 
exec { "create_jar":
    command => "sudo mvn package",
    path    => "/opt/code/bfair_pricing/",
    logoutput => true,
    refreshonly => true 
} -> 

exec { "start_application":
    command => "java -jar ${application_name}",
    path  => "/opt/code/bfair_pricing/target/",
    logoutput => true
} 


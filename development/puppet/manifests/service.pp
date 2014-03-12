


class pricing_service($java_home, $application_name) {
  
  notice("Starting pricing service")
  
 java_service_wrapper::service{ 'bfairpricing':
  run_as_user        => 'root',
  wrapper_java_cmd   => "${java_home}/bin/java", 
  wrapper_mainclass  => 'WrapperJarApp',
  wrapper_additional => ['-Xms1G', '-Xmx1G'],
  wrapper_library    => ['/usr/local/lib'],
  wrapper_classpath  => ['/usr/local/lib/wrapper.jar', "/opt/code/bfair_pricing/target/${application_name}"],
  wrapper_parameter  => ["/opt/code/bfair_pricing/target/${application_name}"]
}
  
  
  
}
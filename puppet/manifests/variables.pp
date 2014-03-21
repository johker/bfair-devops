  
#
# Set Java / Maven home variables  
#
class home_variables($java_home, $maven_version) {
  
  file { "/opt/java.sh":
    mode => 777,
    content => "export JAVA_HOME=${java_home}\nexport PATH=\$PATH:\$JAVA_HOME/bin"
  } 
  file { "/opt/maven.sh":
    mode => 777,
    content => "export M2_HOME=/opt/apache-maven-${maven_version}\nexport M2=%M2_HOME%/bin"
  }  
  exec { "set_java_home":
    command => "/bin/bash /opt/java.sh",
    logoutput => true,
    require => File['/opt/java.sh']
  } 
  exec { "set_maven_home":
    command => "/bin/bash /opt/maven.sh",
    logoutput => true,
    require => File['/opt/maven.sh']
  }  
  
}
  
define maven::install_gem ($version = '', $java_home) {
  exec { "gem $name $version":
    path        => '/usr/bin:/opt/ruby/bin',
    environment => "JAVA_HOME=$java_home",
    command     => "gem install $name --version $version --no-rdoc --no-ri",
    unless      => "gem query -i --name-matches $name --version $version",
    logoutput   => true,
  }
}

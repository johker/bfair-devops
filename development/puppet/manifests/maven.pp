


# Install latest Java 
class { 'java':
  distribution => 'jdk',
  version      => 'latest',
}

# Installing Maven module pre-requisites
class { maven : }
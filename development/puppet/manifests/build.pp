$repo1 = {
  id => "myrepo",
  username => "myuser",
  password => "mypassword",
  url => "http://repo.acme.com",
}
# Install Maven
class { "maven::maven":
  version => "2.2.1",
} ->
# Create a settings.xml with the repo credentials
class { "maven::settings" :
  servers => [$repo1],
}
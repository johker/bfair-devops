package { 'git':
        ensure => installed,
    }

vcsrepo { '/tmp/vcstest-git-clone':
  ensure   => present,
  provider => git,
  require  => [ Package["git"] ],
  source   => 'git://github.com/bruce/rtex.git',
}

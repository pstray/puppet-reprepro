/*

== Class: reprepro::debian

Base class to install reprepro on debian

*/
class reprepro::debian {

  include reprepro::params
  include concat::setup

  case $::lsbdistcodename {
    squeeze: {
      package {'reprepro':
        ensure => 'latest';
      }

      group {'reprepro':
        ensure => present,
      }

      user {'reprepro':
        ensure  => 'present',
        home    => $reprepro::params::basedir,
        shell   => '/bin/bash',
        comment => "Reprepro repository owner",
        gid     => 'reprepro',
        require => Group['reprepro'],
      }

      file {$reprepro::params::basedir:
        ensure => directory,
        owner  => 'reprepro',
        group  => 'reprepro',
        mode   => '0755',
      }

      file {"${reprepro::params::basedir}/.gnupg":
        ensure => directory,
        owner  => 'reprepro',
        group  => 'reprepro',
        mode   => '0700',
      }
    }

    default: {
      fail "reprepro is not available for ${operatingsystem}/${lsbdistcodename}"
    }
  }

}

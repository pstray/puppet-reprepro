# == Definition: reprepro::distribution
#
# Adds a "Distribution" to manage.
#
# === Parameters
#
#   - *ensure* present/absent, defaults to present
#   - *basedir* reprepro basedir
#   - *repository*: the name of the distribution
#   - *origin*: package origin
#   - *label*: package label
#   - *suite*: package suite
#   - *architectures*: available architectures
#   - *components*: available components
#   - *description*: a short description
#   - *sign_with*: email of the gpg key
#   - *deb_indices*: file name and compression
#   - *dsc_indices*: file name and compression
#   - *update*: update policy name
#   - *pull*: pull policy name
#   - *uploaders*: who is allowed to upload packages
#   - *snapshots*: create a reprepro snapshot on each update
#   - *install_cron*: install cron job to automatically include new packages
#   - *not_automatic*: automatic pined to 1 by using NotAutomatic,
#                      value are "yes" or "no"
#   - *but_automatic_upgrades*: set ButAutomaticUpgrades,
#                      value are "yes" or "no"
#   - *create_pull*:       hash to create reprepro::pull resource
#                          the name will be appended to $pull
#   - *create_update*:     hash to create reprepro::update resource
#                          the name will be appended to $update
#   - *create_filterlist*: hash to create reprerpo::filterlist resource
#
# === Requires
#
#   - Class["reprepro"]
#
# === Example
#
#   reprepro::distribution {"lenny":
#     ensure        => present,
#     repository    => "my-repository",
#     origin        => "Camptocamp",
#     label         => "Camptocamp",
#     suite         => "stable",
#     architectures => "i386 amd64 source",
#     components    => "main contrib non-free",
#     description   => "A simple example of repository distribution",
#     sign_with     => "packages@camptocamp.com",
#   }
#
#
define reprepro::distribution (
  $repository,
  $architectures,
  $components,
  $origin                 = undef,
  $label                  = undef,
  $suite                  = undef,
  $description            = undef,
  $sign_with              = '',
  $codename               = $name,
  $ensure                 = present,
  $basedir                = $::reprepro::basedir,
  $homedir                = $::reprepro::homedir,
  $fakecomponentprefix    = undef,
  $udebcomponents         = $components,
  $deb_indices            = 'Packages Release .gz .bz2',
  $dsc_indices            = 'Sources Release .gz .bz2',
  $update                 = '',
  $pull                   = '',
  $uploaders              = '',
  $snapshots              = false,
  $install_cron           = true,
  $not_automatic          = '',
  $but_automatic_upgrades = 'no',
  $log                    = '',
  $create_pull            = {},
  $create_update          = {},
  $create_filterlist      = {},
) {

  include reprepro::params

  # create update and pull resources:
  $_pull   = join(union([$pull],   keys($create_pull)),   ' ')
  $_update = join(union([$update], keys($create_update)), ' ')
  $defaults = {
    repository => $repository,
    basedir    => $basedir,
  }
  create_resources('::reprepro::update', $create_update, $defaults)
  create_resources('::reprepro::pull', $create_pull, $defaults)
  create_resources('::reprepro::filterlist', $create_filterlist, $defaults)

  $notify = $ensure ? {
    'present' => Exec["export distribution ${name}"],
    default => undef,
  }

  concat::fragment { "distribution-${name}":
    target  => "${basedir}/${repository}/conf/distributions",
    content => template('reprepro/distribution.erb'),
    notify  => $notify,
  }

  exec {"export distribution ${name}":
    command     => "su -c 'reprepro -b ${basedir}/${repository} export ${codename}' ${reprepro::user_name}",
    path        => ['/bin', '/usr/bin'],
    refreshonly => true,
    logoutput   => on_failure,
    require     => [
      User[$::reprepro::user_name],
      Reprepro::Repository[$repository]
    ],
  }

  # Configure system for automatically adding packages
  file { "${basedir}/${repository}/tmp/${codename}":
    ensure => directory,
    mode   => '0755',
    owner  => $::reprepro::user_name,
    group  => $::reprepro::group_name,
  }

  if $install_cron {

    if $snapshots {
      $command = "${homedir}/bin/update-distribution.sh -r ${repository} -c ${codename} -s"
    } else {
      $command = "${homedir}/bin/update-distribution.sh -r ${repository} -c ${codename}"
    }

    cron { "${name} cron":
      command     => $command,
      user        => $::reprepro::user_name,
      environment => 'SHELL=/bin/bash',
      minute      => '*/5',
      require     => File["${homedir}/bin/update-distribution.sh"],
    }
  }
}

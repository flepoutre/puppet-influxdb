# == Class: influxdb::repos
#
# This is a container class holding default parameters for influxdb module.
#
# @param apt_location
# @param apt_release
# @param apt_repos
# @param apt_key
# @param influxdb_package_name
# @param influxdb_service_name
#
class influxdb::repos (
  String $apt_location          = $influxdb::params::apt_location,
  String $apt_release           = $influxdb::params::apt_release,
  String $apt_repos             = $influxdb::params::apt_repos,
  String $apt_key               = $influxdb::params::apt_key,
  Array $influxdb_package_name  = $influxdb::params::influxdb_package_name,
  String $influxdb_service_name = $influxdb::params::influxdb_service_name
) inherits influxdb::params {
  case $facts['os']['name'] {
    /(?i:debian|devuan|ubuntu)/: {
      case $facts['os']['distro']['codename'] {
        /(bullseye|n\/a)/   : {
          if !defined(Class['apt']) {
            include apt
          }

          apt::source { 'influxdb':
            ensure   => present,
            location => $apt_location,
            release  => 'buster',
            repos    => 'stable',
            key      => $apt_key,
            notify   => Exec['apt_update'],
          }
        }
        default : {
          if !defined(Class['apt']) {
            include apt
          }

          apt::source { 'influxdb':
            ensure   => present,
            location => $apt_location,
            release  => $apt_release,
            repos    => $apt_repos,
            key      => $apt_key,
            notify   => Exec['apt_update'],
          }
        }
      }
    }
    /(?i:centos|fedora|redhat)/: {
      file { '/etc/yum.repos.d/influxdb.repo':
        ensure  => file,
        backup  => true,
        content => template('influxdb/influxdb.repo.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
      }

      exec { 'influxdb yum update':
        command   => 'yum update -q -y',
        path      => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
        subscribe => File['/etc/yum.repos.d/influxdb.repo'],
      }
    }
    default                    : {
    fail("Module ${module_name} \
      is not supported on ${facts['os']['name']}")
    }
  }
}
# EOF

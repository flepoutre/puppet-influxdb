# == Class: influxdb
#
# Puppet module to install, deploy and configure influxdb.
#
# @param package
# @param service
# @param enable
# @param manage_repo
# @param split_client_package
# @param apt_location
# @param apt_release
# @param apt_repos
# @param apt_key
# @param influxdb_package_name
# @param influxdb_service_name
# @param influxdb_service_provider
# @param hostname
# @param libdir
# @param admin_enable
# @param admin_bind_address
# @param admin_username
# @param admin_password
# @param domain_name
# @param flux_enable
# @param http_enable
# @param http_bind_address
# @param http_auth_enabled
# @param http_realm
# @param http_log_enabled
# @param https_enable
# @param http_bind_socket
# @param logging_format
# @param logging_level
# @param index_version
# @param cache_max_memory_size
# @param cache_snapshot_memory_size
# @param cache_snapshot_write_cold_duration
# @param compact_full_write_old_duration
# @param max_series_per_database
# @param max_values_per_tag
# @param udp_enable
# @param udp_bind_address
# @param graphite_enable
# @param graphite_database
# @param graphite_listen
# @param graphite_templates
#
class influxdb (
  String $package                            = 'true',
  String $service                            = 'true',
  String $enable                             = 'true',
  Boolean $manage_repo                       = true,
  String $split_client_package               = 'false',
  String $apt_location                       = $influxdb::params::apt_location,
  String $apt_release                        = $influxdb::params::apt_release,
  String $apt_repos                          = $influxdb::params::apt_repos,
  String $apt_key                            = $influxdb::params::apt_key,
  Array $influxdb_package_name               = $influxdb::params::influxdb_package_name,
  String $influxdb_service_name              = $influxdb::params::influxdb_service_name,
  String $influxdb_service_provider          = $influxdb::params::influxdb_service_provider,
  String $hostname                           = $facts[networking][fqdn],
  String $libdir                             = $influxdb::params::libdir,
  Boolean $admin_enable                      = $influxdb::params::admin_enable,
  String $admin_bind_address                 = $influxdb::params::admin_bind_address,
  String $admin_username                     = $influxdb::params::admin_username,
  Optional[String] $admin_password           = $influxdb::params::admin_password,
  Optional[String] $domain_name              = $influxdb::params::domain_name,
  Optional[Boolean] $flux_enable             = $influxdb::params::flux_enable,
  Boolean $http_enable                       = $influxdb::params::http_enable,
  String $http_bind_address                  = $influxdb::params::http_bind_address,
  Boolean $http_auth_enabled                 = $influxdb::params::http_auth_enabled,
  String $http_realm                         = $influxdb::params::http_realm,
  Boolean $http_log_enabled                  = $influxdb::params::http_log_enabled,
  Boolean $https_enable                      = $influxdb::params::https_enable,
  String $http_bind_socket                   = $influxdb::params::http_bind_socket,
  String $logging_format                     = $influxdb::params::logging_format,
  String $logging_level                      = $influxdb::params::logging_level,
  Optional[String] $index_version            = $influxdb::params::index_version,
  String $cache_max_memory_size              = $influxdb::params::cache_max_memory_size,
  String $cache_snapshot_memory_size         = $influxdb::params::cache_snapshot_memory_size,
  String $cache_snapshot_write_cold_duration = $influxdb::params::cache_snapshot_write_cold_duration,
  String $compact_full_write_old_duration    = $influxdb::params::compact_full_write_old_duration,
  String $max_series_per_database            = $influxdb::params::max_series_per_database,
  String $max_values_per_tag                 = $influxdb::params::max_values_per_tag,
  Boolean $udp_enable                        = $influxdb::params::udp_enable,
  String $udp_bind_address                   = $influxdb::params::udp_bind_address,
  Boolean $graphite_enable                   = $influxdb::params::graphite_enable,
  String $graphite_database                  = $influxdb::params::graphite_database,
  String $graphite_listen                    = $influxdb::params::graphite_listen,
  Array $graphite_templates                  = $influxdb::params::graphite_templates,
) inherits influxdb::params {
  case $split_client_package {
    'true'    : { $package_names = $influxdb_package_name }
    'false'   : { $package_names = [$influxdb_package_name[0]] }
    default : { fail('split_client_package package must be true (if using Debian/Ubuntu distro packages) or false') }
  }

  case $package {
    true    : { $ensure_package = 'present' }
    false   : { $ensure_package = 'purged' }
    'latest'  : { $ensure_package = 'latest' }
    default : { fail('package must be true, false or latest') }
  }

  case $service {
    true    : { $ensure_service = 'running' }
    false   : { $ensure_service = 'stopped' }
    'running' : { $ensure_service = 'running' }
    default : { fail('service must be true, false or running') }
  }

  if ($manage_repo == true) {
    class { 'influxdb::repos':
      apt_location          => $apt_location,
      apt_release           => $apt_release,
      apt_repos             => $apt_repos,
      apt_key               => $apt_key,
      influxdb_package_name => $package_names,
      influxdb_service_name => $influxdb_service_name,
    }

    package { $package_names:
      ensure  => $ensure_package,
      require => Class['influxdb::repos'],
    }
  }
  else {
    package { $package_names:
      ensure  => $ensure_package,
    }
  }

  service { $influxdb_service_name:
    ensure     => $ensure_service,
    enable     => $enable,
    hasrestart => true,
    hasstatus  => true,
    provider   => $influxdb_service_provider,
    require    => Package[$package_names[0]],
  }

  if $ensure_service == 'running' {
    exec { 'wait_for_influxdb_to_listen':
      command   => 'influx -execute quit',
      unless    => 'influx -execute quit',
      tries     => '3',
      try_sleep => '10',
      require   => Service[$influxdb_service_name],
      path      => '/bin:/usr/bin',
    }

    if $http_auth_enabled {
      if $https_enable {
        $influx_init_cmd = 'influx -ssl -unsafeSsl'
      } else {
        $influx_init_cmd = 'influx'
      }
      exec { 'create_influxdb_admin_user':
        path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin',
        command => "${influx_init_cmd} -execute \
            \"CREATE USER ${admin_username} WITH PASSWORD '${admin_password}' WITH ALL PRIVILEGES\"",
        unless  => "${influx_init_cmd} \
            -username ${admin_username} -password '${admin_password}' -execute \
            'SHOW USERS' | tail -n+3 | awk '{print \$1}' | grep -x ${admin_username}",
        require => Exec['wait_for_influxdb_to_listen'],
      }
    }
  }

  file { '/etc/influxdb/influxdb.conf':
    ensure  => $ensure_package,
    path    => '/etc/influxdb/influxdb.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('influxdb/influxdb.conf.erb'),
    require => Package[$influxdb_package_name[0]],
    notify  => Service[$influxdb_service_name],
  }
}
# EOF

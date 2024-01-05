# == Class: influxdb::database
#
# @param ensure
# @param db_name
# @param https_enable
# @param http_auth_enabled
# @param admin_username
# @param admin_password
#
define influxdb::database (
  Enum['absent', 'present'] $ensure  = present,
  String $db_name                    = $title,
  Boolean $https_enable              = $influxdb::https_enable,
  Boolean $http_auth_enabled         = $influxdb::http_auth_enabled,
  String $admin_username             = $influxdb::admin_username,
  Optional[String] $admin_password   = $influxdb::admin_password,
) {
  if $https_enable {
    $ssl_opts = '-ssl -unsafeSsl'
  } else {
    $ssl_opts = ''
  }

  if $http_auth_enabled {
    $auth_opts = "-username ${admin_username} -password '${admin_password}'"
  } else {
    $auth_opts = ''
  }

  $cmd = "influx ${ssl_opts} ${auth_opts}"

  if ($ensure == 'absent') {
    exec { "drop_database_${db_name}":
      path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin',
      command => "${cmd} \
        -execute 'DROP DATABASE ${db_name}'",
      onlyif  => "${cmd} \
        -execute 'SHOW DATABASES' | tail -n+3 | grep -x ${db_name}",
      require => Class['influxdb'],
    }
  } elsif ($ensure == 'present') {
    exec { "create_database_${db_name}":
      path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin',
      command => "${cmd} \
        -execute 'CREATE DATABASE ${db_name}'",
      unless  => "${cmd} \
        -execute 'SHOW DATABASES' | tail -n+3 | grep -x ${db_name}",
      require => Class['influxdb'],
    }
  }
}
# EOF

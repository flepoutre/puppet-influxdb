# == Class: influxdb::user
#
# @param ensure
# @param db_user
# @param passwd
# @param is_admin
# @param https_enable
# @param http_auth_enabled
# @param admin_username
# @param admin_password
#
define influxdb::user (
  Enum['absent', 'present'] $ensure = present,
  String $db_user                   = $title,
  Optional[String] $passwd          = undef,
  Boolean $is_admin                 = false,
  Boolean $https_enable             = $influxdb::https_enable,
  Boolean $http_auth_enabled        = $influxdb::http_auth_enabled,
  String $admin_username            = $influxdb::admin_username,
  Optional[String] $admin_password  = $influxdb::admin_password,
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
    exec { "drop_user_${db_user}":
      path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin',
      command => "${cmd} \
        -execute 'DROP USER \"${db_user}\"'",
      onlyif  => "${cmd} \
        -execute 'SHOW USERS' | tail -n+3 | awk '{print \$1}' |\
        grep -x ${db_user}",
    }
  } elsif ($ensure == 'present') {
    $arg_p = "WITH PASSWORD '${passwd}'"
    if $is_admin {
      $arg_a = 'WITH ALL PRIVILEGES'
    } else {
      $arg_a = ''
    }
    exec { "create_user_${db_user}":
      path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin',
      command => "${cmd} \
        -execute \"CREATE USER \\\"${db_user}\\\" ${arg_p} ${arg_a}\"",
      unless  => "${cmd} \
        -execute 'SHOW USERS' | tail -n+3 | awk '{print \$1}' |\
        grep -x ${db_user}",
    }
  }
}
# EOF

# == Class: influxdb::privilege
#
# @param ensure
# @param db_user
# @param db_name
# @param privilege
# @param https_enable
# @param http_auth_enabled
# @param admin_username
# @param admin_password
#
define influxdb::privilege (
  Enum['absent', 'present'] $ensure       = present,
  Optional[String] $db_user               = undef,
  Optional[String] $db_name               = undef,
  Enum['ALL', 'READ', 'WRITE'] $privilege = 'ALL',
  Boolean $https_enable                   = $influxdb::https_enable,
  Boolean $http_auth_enabled              = $influxdb::http_auth_enabled,
  String $admin_username                  = $influxdb::admin_username,
  Optional[String] $admin_password        = $influxdb::admin_password,
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

  $matches = "grep ${db_name} | grep ${privilege}"

  if ($ensure == 'absent') {
    exec { "revoke_${privilege}_on_${db_name}_to_${db_user}":
      path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin',
      command => "${cmd} \
         -execute 'REVOKE ${privilege} ON \"${db_name}\" TO \"${db_user}\"'",
      onlyif  => "${cmd} \
        -execute  'SHOW GRANTS FOR \"${db_user}\"' | ${matches}",
    }
  } elsif ($ensure == 'present') {
    exec { "grant_${privilege}_on_${db_name}_to_${db_user}":
      path    => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin',
      command => "${cmd} \
        -execute 'GRANT ${privilege} ON \"${db_name}\" TO \"${db_user}\"'",
      unless  => "${cmd} \
        -execute 'SHOW GRANTS FOR \"${db_user}\"' | ${matches}",
    }
  }
}
# EOF

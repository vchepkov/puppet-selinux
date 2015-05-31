# Class: selinux::package
#
# This module manages additional packages required to support some of the functions.
#
# Parameters:
#
# There are no default parameters for this class.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
class selinux::package {

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  $ensure = $::selinux::mode ? {
    'disabled' => 'absent',
    default    => 'installed',
  }
  package { $::selinux::params::package_name:
    ensure => $ensure,
  }

  package { "selinux-policy-${::selinux::policy}":
    ensure => $ensure,
    notify => $::selinux::mode ? {
      'disabled' => undef,
      default    => Exec['selinux_autorelabel'],
    },
  }

  exec { 'selinux_autorelabel':
    command     => 'touch /.autorelabel',
    path        => '/bin:/usr/bin',
    refreshonly => true,
  }
}

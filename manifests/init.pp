# Class: selinux
#
# Description
#  This class manages SELinux on RHEL based systems.
#
# Parameters:
#  - $mode (enforcing|permissive|disabled) - sets the operating state for SELinux.
#
# Actions:
#  This module will configure SELinux and/or deploy SELinux based modules to running
#  system.
#
# Sample Usage:
#  include selinux
#
class selinux (
  $mode           = $selinux::params::mode,
  $package_ensure = $selinux::params::package_ensure,
  $sx_mod_dir     = $selinux::params::sx_mod_dir,
) inherits selinux::params {

  class { 'selinux::package': } ->
  class { 'selinux::config': }
}

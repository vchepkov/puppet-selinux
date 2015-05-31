# Class: selinux
#
# Description
#  This class manages SELinux on RHEL based systems.
#
# Parameters:
#  - $mode (enforcing|permissive|disabled) - sets the operating state for SELinux.
#  - $sx_mod_dir
#  - $policy
#
# Actions:
#  This module will configure SELinux and/or deploy SELinux based modules to running
#  system.
#
# Sample Usage:
#  include selinux
#
class selinux (
  $mode       = $selinux::params::mode,
  $sx_mod_dir = $selinux::params::sx_mod_dir,
  $policy     = $selinux::params::policy,
) inherits selinux::params {

  class { 'selinux::package': } ->
  class { 'selinux::config': }
}

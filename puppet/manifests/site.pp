# site.pp
#
# Baseline security hardening via Puppet — the third automation tool
# the target company mentions (alongside Ansible and Terraform).
#
# This does the SAME job as ansible/provision-paved-road.yml's hardening
# section, but via Puppet's declarative model instead of Ansible's
# task-based model. Having both demonstrates the paved road works
# regardless of which config management tool a given team already uses —
# exactly the "diverse environment" the target company describes.
#
# Apply with:
#   puppet apply site.pp
# Or, in a real Puppet server setup, this would be assigned to nodes
# via Hiera/node classification rather than run standalone.

node default {

  # Ensure automatic security updates are installed
  package { 'unattended-upgrades':
    ensure => installed,
  }

  # Disable password authentication over SSH (key-only access)
  file_line { 'ssh_disable_password_auth':
    path  => '/etc/ssh/sshd_config',
    line  => 'PasswordAuthentication no',
    match => '^#?PasswordAuthentication',
    notify => Service['sshd'],
  }

  # Disable root login over SSH
  file_line { 'ssh_disable_root_login':
    path   => '/etc/ssh/sshd_config',
    line   => 'PermitRootLogin no',
    match  => '^#?PermitRootLogin',
    notify => Service['sshd'],
  }

  service { 'sshd':
    ensure => running,
    enable => true,
  }

  # Ensure the firewall (ufw) is installed and enabled
  package { 'ufw':
    ensure => installed,
  }

  exec { 'ufw_default_deny':
    command => '/usr/sbin/ufw default deny incoming',
    unless  => '/usr/sbin/ufw status verbose | grep -q "deny (incoming)"',
    require => Package['ufw'],
  }

  exec { 'ufw_allow_ssh':
    command => '/usr/sbin/ufw allow 22/tcp',
    unless  => '/usr/sbin/ufw status | grep -q "22/tcp.*ALLOW"',
    require => Exec['ufw_default_deny'],
  }

  exec { 'ufw_enable':
    command => '/usr/sbin/ufw --force enable',
    unless  => '/usr/sbin/ufw status | grep -q "Status: active"',
    require => Exec['ufw_allow_ssh'],
  }

  # Ensure fail2ban is installed and running (brute-force protection)
  package { 'fail2ban':
    ensure => installed,
  }

  service { 'fail2ban':
    ensure  => running,
    enable  => true,
    require => Package['fail2ban'],
  }
}

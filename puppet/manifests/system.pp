# Set Exec Defaults
Exec {
  user      => 'root',
  path      => ['/bin', '/usr/bin', '/usr/local/bin', '/opt/puppetlabs/bin'],
  logoutput => false,
}

# (Optional) Update Package Repositories
$repo_upd = hiera('system::repo_update', undef)
if $repo_upd {
  exec { 'update repositories':
    command => $repo_upd,
  }

  Package {
    require => Exec['update repositories'],
  }
}

# Manage Puppet
class { 'puppet_agent': service_names => [] }

# Install Base Packages
$packages = hiera_array('system::packages', [])
package { $packages:
  ensure => installed,
}

# Configure Admin User
$user  = hiera_hash('user::account')
$uname = $user['name']
$uhome = $user['home_dir']
create_resources('account', {"${uname}" => $user})

# Perform User Setup
Account[$uname] ->
exec { 'user configuration':
  command     => "puppet apply ${::puppet_args} puppet/manifests/user.pp",
  user        => $uname,
  cwd         => $::puppet_cwd,
  path        => $upath,
  returns     => [0, 2],
  environment => ["HOME=${uhome}"],
  logoutput   => true,
  require     => Class['puppet_agent'],
}

# Set Exec Defaults
Exec {
  user      => 'root',
  path      => ['/bin', '/usr/bin', '/usr/local/bin'],
  logoutput => false,
}

# (Optional) Update Package Repositories
$repo_upd = hiera('system::repo_update', undef)
if $repo_upd {
  exec { 'update repositories':
    command => $repo_upd
  }

  Package {
    require => Exec['update repositories'],
  }
}

# Install Base Packages
$packages = hiera_array('system::packages', [])
package { $packages:
  ensure => installed,
}

# Configure Admin User
$user  = hiera_hash('user::account')
$uname = $user['name']
$uhome = $user['home']
$upath = hiera_array('user::path')
create_resources('account', {$uname => $user})

# Perform User Setup
Account[$uname] ->
exec { 'user configuration':
  command   => "puppet apply ${::puppet_args} puppet/manifests/user.pp",
  user      => $uname,
  cwd       => $uhome,
  path      => $upath,
  returns   => [0, 2],
  logoutput => true,
}

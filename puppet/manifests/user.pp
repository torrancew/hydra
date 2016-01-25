# Admin User Information
$user  = hiera_hash('user::account')
$uname = $user['name']
$uhome = $user['home_dir']
$upath = hiera_array('user::path')

# Set Exec Defaults
Exec {
  user        => $uname,
  cwd         => $uhome,
  path        => $upath,
  environment => ["HOME=${uhome}", "XDG_CONFIG_HOME=${uhome}/.config"],
  logoutput   => false,
}

# mr Configuration
$mr_ctrl_repo = hiera('user::mr_ctrl_repo')
exec { 'checkout mr control repo':
  command => "vcsh clone ${mr_ctrl_repo} mr",
  creates => "${home}/.config/mr",
}

# Enable Selected Dotfile Repositories
$mr_repos = hiera_array('user::mr_repos', [])
$mr_repos.each |String $repo| {
  file { "${repo} mr config":
    ensure  => link,
    path    => "${uhome}/.config/mr/config.d/${repo}.vcsh",
    target  => "../available.d/${repo}.vcsh",
    require => Exec['checkout mr control repo'],
    notify  => Exec['checkout dotfile repos'],
  }
}

# Checkout Dotfile Repositories
exec { 'checkout dotfile repos':
  command     => "mr -j ${::processorcount} up",
  refreshonly => true,
  require     => Exec['checkout mr control repo'],
}

# Perform User Execs
$execs = hiera_hash('user::execs', {})
create_resources('exec', $execs)

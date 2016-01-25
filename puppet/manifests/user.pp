# Admin User Information
$user  = hiera_hash('user::account')
$uname = $user['name']
$uhome = $user['home']
$upath = hiera_array('user::path')

# Set Exec Defaults
Exec {
  user      => $uname,
  cwd       => $uhome,
  path      => $upath,
  logoutput => false,
}

# mr Configuration
$mr_ctrl_repo = hiera('user::mr_ctrl', 'https://github.com/RichiH/vcsh_mr_template.git')
exec { 'checkout mr control repo':
  command => "vcsh clone ${mr_ctrl_repo} mr",
  creates => "${home}/.config/mr",
}

# Enable Selected Dotfile Repositories
$mr_repos = hiera_array('user::mr_repos', [])
$mr_repos.each |String $repo| {
  exec { "enable ${repo} mr repo":
    command => "ln -s ../available.d/${repo}.vcsh ./",
    cwd     => "${uhome}/.config/mr/config.d",
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

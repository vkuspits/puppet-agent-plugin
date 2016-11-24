notice('MODULAR: puppet-agent-plugin/deploy-puppet-agent.pp')

$puppet-version           = '3.8'
$puppet-agent-plugin_data = hiera('puppet-agent-plugin', {})
$puppet-master-ip         = $puppet-agent-plugin_data['puppet-master-ip']
$puppet-master-hostname   = $puppet-agent-plugin_data['puppet-master-hostname']
$node-ip                  = hiera('', {})
$node-hostname            = hiera('hostname', {})
$puppet-agent-service     = 'puppet-agent'

if $::osfamily == 'Debian' {
  $required_packages = []
  
  package { $required_packages:
    ensure          => present,
    provider        => 'apt',
    install_options => [ { 'version' => $puppet-version } ]
  }

  file_line { 'hosts':
    ensure => present,
    path   => '/etc/hosts',
    line   => '${puppet-master-ip} ${puppet-master-hostname}'
  }

  file_line { 'hosts':
    ensure => present,
    path   => '/etc/hosts',
    line   => '${node-ip} ${node-hostname}'
  }

  file_line { 'puppet.conf';
    path   => '/etc/puppet/puppet.conf',
    line   => 'server = ${puppet-master-hostname}',
    match  => '^server ='
  }  

  exec { 'create sertificate':
    command => 'puppet agent --server $puppet-master-hostname --waitforcert 60 --test',
    path    => "/usr/bin:/usr/sbin:/bin"
  }
  
  service { $puppet-agent-service:
    ensure => running,
    start  => 'puppet agent'
  }

  exec { 'puppet-agent autostart':
    command => 'chkconfig puppet on',
    path    => "/usr/bin:/usr/sbin:/bin"
  }
}
else {
  fail("Unsuported osfamily ${::osfamily}, currently Debian are the only supported platforms")
}

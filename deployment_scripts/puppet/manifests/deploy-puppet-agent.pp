notice('MODULAR: puppet-agent-plugin/deploy-puppet-agent.pp')

$puppet-version           = '3.8'
$puppet-agent-plugin_data = hiera('puppet-agent', {})
$no-dns-server            = $puppet-agent-plugin_data['no-dns']
$puppet-master-ip         = $puppet-agent-plugin_data['puppet-master-ip']
$puppet-master-hostname   = $puppet-agent-plugin_data['puppet-master-hostname']
$node-ip                  = hiera('', {})
$node-hostname            = hiera('hostname', {})
$use-cron                 = $puppet-agent-plugin_data['use-cron']
$cron-str                 = $puppet-agent-plugin_data['cron-conf']
$cron-conf                = spilt($cron-str, ' ')
$puppet-agent-service     = 'puppet-agent'

if $::osfamily == 'Debian' {
  $required_packages = 'puppet'
  
  package { $required_packages:
    ensure   => $puppet-version,
    provider => 'apt',
    before   => File_line['puppet.conf']
  }
#if we had DNS-server we need't this two resources
if $no-dns-server == true {
#config /etc/hosts for puppet agent
  file_line { 'hosts':
    ensure => present,
    path   => '/etc/hosts',
    line   => "${puppet-master-ip} ${puppet-master-hostname}"
  }

  file_line { 'hosts':
    ensure => present,
    path   => '/etc/hosts',
    line   => "${node-ip} ${node-hostname}"
  }
}
#
  file_line { 'puppet.conf':
    path   => '/etc/puppet/puppet.conf',
    line   => "server = ${puppet-master-hostname}",
    match  => '^server =',
    notify => exec['create certificate']
  }

  exec { 'create sertificate':
    command => 'puppet agent --server $puppet-master-hostname --waitforcert 60 --test',
    path    => '/usr/bin:/usr/sbin:/bin',
    notify  => service[$puppet-agent-service]
  }
if $use-cron == true {
#Set up cron job for puppet agent
  cron {  'puppet-cron':
    command  => '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --splay --splaylimit 60',
    user     => root,
    minute   => $cron-conf[0],
    hour     => $cron-conf[1],
    month    => $cron-conf[3],
    monthday => $cron-conf[2],
    weekday  => $cron-conf[4]
  }
}
else {
#use puppet agent as service
  service { $puppet-agent-service:
    ensure => running,
    start  => 'puppet agent',
    notify => exec['puppet-agent autostart']
  }

  exec { 'puppet-agent autostart':
    command => 'chkconfig puppet on',
    path    => '/usr/bin:/usr/sbin:/bin'
  }
}
}
else {
  fail("Unsuported osfamily ${::osfamily}, currently Debian are the only supported platforms")
}

notice('MODULAR: puppet-agent-plugin/deploy-puppet-agent.pp')

$puppet_version           = '3.8'
$puppet_agent_plugin_data = hiera('puppet-agent', {})
$no_dns_server            = $puppet_agent_plugin_data['no-dns']
$puppet_master_ip         = $puppet_agent_plugin_data['puppet_master_ip']
$puppet_master_hostname   = $puppet_agent_plugin_data['puppet_master_hostname']
$node_ip                  = hiera('', {})
$node_hostname            = hiera('hostname', {})
$use_cron                 = $puppet_agent_plugin_data['use_cron']
$cron_str                 = $puppet_agent_plugin_data['cron_conf']
$cron_conf                = spilt($cron_str, ' ')
$puppet_agent_service     = 'puppet-agent'

if $::osfamily == 'Debian' {
  $required_packages = 'puppet'
  
  package { $required_packages:
    ensure   => $puppet_version
  }
#if we had DNS-server we need't this two resources
if $no_dns_server == true {
#config /etc/hosts for puppet agent
  host { 'puppet-master':
    name    => $puppet_master_hostname,
    ip      => $puppet_master_ip,
    comment => 'Address of puppet-master'
  }

  host { 'puppet-agent':
    name    => $node_hostname,
    ip      => $node_ip,
    comment => 'Address of puppet-agent'
  }
}
#
  puppet_config {
    'agent/server': value => $puppet_master_hostname;
  }
  #file_line { 'puppet.conf':
  #  path   => '/etc/puppet/puppet.conf',
  #  line   => "server = ${puppet_master_hostname}",
  #  match  => '^server =',
  #  notify => exec['create certificate']
  }
if $use_cron == true {
#Set up cron job for puppet agent
  cron {  'puppet-cron':
    command  => '/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --splay --splaylimit 60',
    user     => root,
    minute   => $cron_conf[0],
    hour     => $cron_conf[1],
    month    => $cron_conf[3],
    monthday => $cron_conf[2],
    weekday  => $cron_conf[4]
  }
}
else {
#use puppet agent as service
  service { $puppet_agent_service:
    ensure => running
  }
}
}
else {
  fail("Unsuported osfamily ${::osfamily}, currently Debian are the only supported platforms")
}

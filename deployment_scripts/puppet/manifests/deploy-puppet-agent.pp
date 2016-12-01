notice('MODULAR: puppet-agent-plugin/deploy-puppet-agent.pp')

$puppet_agent_plugin_data = hiera('puppet-agent', {})
$no_dns_server            = $puppet_agent_plugin_data['no-dns']
$puppet_master_ip         = $puppet_agent_plugin_data['puppet-master-ip']
$puppet_master_hostname   = $puppet_agent_plugin_data['puppet-master-hostname']
$node                     = hiera('provision', {})
$node_ip                  = $node['power_address']
$node_hostname            = hiera('fqdn', {})
$agent_type               = $puppet_agent_plugin_data['agent-type']
$cron_str                 = $puppet_agent_plugin_data['cron-conf']
$cron_conf                = split($cron_str, ' ')
$puppet_agent_service     = 'puppet'

$length       = inline_template('<%= @cron_conf.length %>') - 1
$cron_command = inline_template('<%= @cron_conf[6..$length].join(" ") %>')


if $::osfamily == 'Debian' {
  $required_packages = 'puppet'
  
  package { $required_packages:
    ensure   => $puppet_version,
  }
#if we had DNS-server we need't this two resources
if $no_dns_server == true {
#config /etc/hosts for puppet agent
  host { 'puppet-master':
    name    => $puppet_master_hostname,
    ip      => $puppet_master_ip,
    comment => 'Address of puppet-master',
  }

  host { 'puppet-agent':
    name    => $node_hostname,
    ip      => $node_ip,
    comment => 'Address of puppet-agent',
  }
}
#
  puppet_config {
    'agent/server': value => $puppet_master_hostname;
  }
if $agent_type == 'cron' {
#Set up cron job for puppet agent
  cron {  'puppet-cron':
    command  => $cron_command,
    user     => root,
    minute   => $cron_conf[0],
    hour     => $cron_conf[1],
    month    => $cron_conf[3],
    monthday => $cron_conf[2],
    weekday  => $cron_conf[4],
  }
}
else {
#use puppet agent as service
  service { $puppet_agent_service:
    ensure => running,
  }
}
}
else {
  fail("Unsuported osfamily ${::osfamily}, currently Debian are the only supported platforms")
}

notice('MODULAR: puppet-agent-plugin/deploy-puppet-agent.pp')

$puppet_agent_plugin_data = hiera('puppet-agent', {})
$no_dns_server            = $puppet_agent_plugin_data['no-dns']
$puppet_master_ip         = $puppet_agent_plugin_data['puppet-master-ip']
$puppet_master_hostname   = $puppet_agent_plugin_data['puppet-master-hostname']
$node                     = hiera('provision', {})
$node_ip                  = $node['power_address']
$node_hostname            = hiera('fqdn', {})
$enable_puppet            = $puppet_agent_plugin_data['enable-puppet-agent']
$agent_type               = $puppet_agent_plugin_data['agent-type']
$cron_str                 = $puppet_agent_plugin_data['cron-conf']
$cron_conf                = split($cron_str, ' ')
$puppet_agent_service     = 'puppet'

$cron_command = inline_template('<%= @cron_conf[5..-1].join(" ") %>')


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
if $enable_puppet == true {
  $status = 'present'
}
else {
  $status = 'absent'
}
  cron {  'puppet-cron':
    ensure   => $status,
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
if $enable_puppet == true{
  $status = 'running'
}
else {
  $status = 'stopped'
}
#use puppet agent as service
  service { $puppet_agent_service:
    ensure => $status,
  }
}
}
else {
  fail("Unsuported osfamily ${::osfamily}, currently Debian are the only supported platforms")
}

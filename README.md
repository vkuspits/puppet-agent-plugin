Puppet-agent plugin
============

Plugin for insrallation puppet-agent on fuel nodes
for managing nodes by puppet-master.

Installation of plugin
============

##### Clone or download this repo
```
git clone git@github.com:vkuspits/puppet-agent-plugin.git
```
##### Build this plugin by [Fuel plugin builder](https://github.com/openstack/fuel-plugins)
```
fpb --build /.../puppet-agent-plugin
```
##### Copy plugin to your's fuel-master node
```
scp /dir/to/puppet-agent-plugin.rpm root@fuel:/tmp
```
##### Install
```
fuel plugins --install /tmp/puppet-agent-plugin.rpm
```
:shipit:

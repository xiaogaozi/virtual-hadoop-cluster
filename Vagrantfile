# -*- mode: ruby -*-
# vi: set ft=ruby :

$hosts_script = <<SCRIPT
cat > /etc/hosts <<EOF
127.0.0.1       localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
SCRIPT

hosts = [
  { "name" => "master", "hostname" => "vm-cdh-cluster-nn1", "memory" => "1024", "ip" => "10.211.55.100" },
  { "name" => "standby", "hostname" => "vm-cdh-cluster-nn2", "memory" => "512", "ip" => "10.211.55.101" },
  { "name" => "slave1", "hostname" => "vm-cdh-cluster-dn1", "memory" => "1024", "ip" => "10.211.55.110" },
  { "name" => "slave2", "hostname" => "vm-cdh-cluster-dn2", "memory" => "1024", "ip" => "10.211.55.111" },
  { "name" => "slave3", "hostname" => "vm-cdh-cluster-dn3", "memory" => "1024", "ip" => "10.211.55.112" },
]

Vagrant.configure("2") do |config|

  # Define base image
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  # Manage /etc/hosts on host and VMs
  config.hostmanager.enabled = false
  config.hostmanager.manage_host = true
  config.hostmanager.include_offline = true
  config.hostmanager.ignore_private_ip = false

  hosts.each do |host|
    config.vm.define host["name"] do |vmconfig|
      vmconfig.vm.provider :virtualbox do |v|
        v.name = host["hostname"]
        v.customize ["modifyvm", :id, "--memory", host["memory"]]
      end
      vmconfig.vm.network :private_network, ip: host["ip"]
      vmconfig.vm.hostname = "%s.example.com" % host["hostname"]
      vmconfig.hostmanager.aliases = [host["hostname"]]
      vmconfig.vm.provision :shell, :inline => $hosts_script
      vmconfig.vm.provision "hostmanager"
      vmconfig.vm.provision "puppet" do |puppet|
        puppet.module_path = "modules"
      end
    end
  end

end

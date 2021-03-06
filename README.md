# A working virtual Hadoop cluster

With these files you can setup and provision a locally running, virtual Hadoop cluster in real distributed fashion for trying out Hadoop and related technologies. It runs the latest Cloudera Hadoop distribution: **CDH 5**.


## Specs

The cluster conists of 5 nodes:

* Master node with 1GB of RAM (Running the NameNode, Hue, ResourceManager, HBase Master etc. after installing the Hadoop services)
* Standby node with 512M of RAM (Running the standby NameNode)
* 3 slaves with 1GB of RAM each (Running DataNodes, ZooKeeper, HBase RegionServer and HBase Thrift Server)

As you can see, you'll need at least 5GB of free RAM to run this. If you have less, you can try to remove one machine from the Vagrantfile. This will lead to worse performance though!


## Usage

Depending on the hardware of your computer and your network, installation will probably take hours.

First install [VirtualBox](https://www.virtualbox.org) and [Vagrant](http://www.vagrantup.com).

Install the Vagrant [Hostmanager plugin](https://github.com/smdahlen/vagrant-hostmanager):

```bash
$ vagrant plugin install vagrant-hostmanager
```

Clone this repository:

```bash
$ git clone https://github.com/xiaogaozi/virtual-hadoop-cluster.git
```

Provision the bare cluster. It will ask you to enter your password, so it can modify your `/etc/hosts` file for easy access in your browser. It uses the Vagrant Hostmanager plugin to do this.

```bash
$ cd virtual-hadoop-cluster
$ librarian-puppet install
$ vagrant up
```

You can visit following addresses to ensure everything is OK:

- HDFS: [http://vm-cdh-cluster-nn1.example.com:50070](http://vm-cdh-cluster-nn1.example.com:50070)
- MapReduce: [http://vm-cdh-cluster-nn1.example.com:8088](http://vm-cdh-cluster-nn1.example.com:8088)
- HBase: [http://vm-cdh-cluster-nn1.example.com:60010](http://vm-cdh-cluster-nn1.example.com:60010)

Have fun with your Hadoop cluster.

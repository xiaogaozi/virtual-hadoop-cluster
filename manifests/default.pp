# -*- tab-width: 2; indent-tabs-mode: nil -*-
# vim: set tabstop=2 shiftwidth=2 softtabstop=2 expandtab:

stage { 'pre':
  before => Stage['main']
}

Class['apt::update'] -> Package <| |>

class repo {
  class { 'apt':
    always_apt_update  => true,
    purge_sources_list => true
  }
  apt::source { 'ubuntu':
    location    => 'http://mirrors.aliyun.com/ubuntu',
    release     => $::lsbdistcodename,
    repos       => 'main restricted universe multiverse',
    include_src => false
  }
  apt::source { 'ubuntu_updates':
    location    => 'http://mirrors.aliyun.com/ubuntu',
    release     => "${::lsbdistcodename}-updates",
    repos       => 'main restricted universe multiverse',
    include_src => false
  }
  apt::source { 'ubuntu_security':
    location    => 'http://security.ubuntu.com/ubuntu',
    release     => "${::lsbdistcodename}-security",
    repos       => 'main restricted universe multiverse',
    include_src => false
  }
  apt::source { 'cdh':
    location     => "http://archive.cloudera.com/cdh5/ubuntu/${::lsbdistcodename}/amd64/cdh",
    release      => "${::lsbdistcodename}-cdh5",
    repos        => 'contrib',
    architecture => 'amd64',
    key          => '02A818DD',
    key_source   => "http://archive.cloudera.com/cdh5/ubuntu/${::lsbdistcodename}/amd64/cdh/archive.key",
    include_src  => false
  }
}

class hadoop::params {
  $namenode_host = 'vm-cdh-cluster-nn1.example.com'
  $datanode_hosts = [
    'vm-cdh-cluster-dn1.example.com',
    'vm-cdh-cluster-dn2.example.com',
    'vm-cdh-cluster-dn3.example.com'
  ]
  $zookeeper_hosts = $datanode_hosts
  $hbase_version = '0.98.6+cdh5.2.0+55-1.cdh5.2.0.p0.33~precise-cdh5.2.0'
}

class hadoop::base {
  class { 'repo':
    stage => 'pre'
  }
  class { 'java':
    distribution => 'jre',
    stage        => 'pre'
  }

  include hadoop::params

  file {
    '/var/lib/hadoop':
      ensure => directory,
      before => File['/var/lib/hadoop/data'];
    '/var/lib/hadoop/data':
      ensure => directory,
      before => Class['cdh::hadoop'];
  }
  class { 'cdh::hadoop':
    cluster_name    => 'mycluster',
    namenode_hosts  => [$hadoop::params::namenode_host],
    datanode_mounts => [
      '/var/lib/hadoop/data/a',
      '/var/lib/hadoop/data/b',
      '/var/lib/hadoop/data/c'
    ],
    dfs_name_dir    => '/var/lib/hadoop/name',
    webhdfs_enabled => true,
    httpfs_enabled  => false,
    lzo_enabled     => true
  }

  class { 'cdh::hive':
    metastore_host   => $hadoop::params::namenode_host,
    zookeeper_hosts  => $hadoop::params::zookeeper_hosts,
    jdbc_host        => 'localhost',
    jdbc_database    => 'hive',
    jdbc_username    => 'root',
    jdbc_password    => 'root',
    db_root_username => 'root',
    db_root_password => 'root'
  }

  class { 'cdh::oozie':
    oozie_host => $hadoop::params::namenode_host
  }

  # HBase
  class { 'cdh::hbase':
    version         => $hadoop::params::hbase_version,
    namenode_host   => $hadoop::params::namenode_host,
    zookeeper_hosts => $hadoop::params::zookeeper_hosts
  }
}

class my::hadoop::master inherits hadoop::base {
  include hadoop::params
  include cdh::hadoop::master
  include cdh::hive::master

  class { 'mysql::server':
    root_password => 'root',
    stage         => 'pre'
  }

  file { '/var/lib/oozie':
    ensure => directory,
    before => Class['cdh::oozie::server']
  }
  class { 'cdh::oozie::server':
    jdbc_host        => 'localhost',
    jdbc_database    => 'oozie',
    jdbc_username    => 'root',
    jdbc_password    => 'root',
    db_root_username => 'root',
    db_root_password => 'root'
  }

  class { 'cdh::hue':
    secret_key       => 's=yt($8oeyh#c5u7^480yzk_%*b#q@4)(7rkw5#9#i&7ha@=w!',
    hive_server_host => $hadoop::params::namenode_host,
    timezone         => 'Asia/Shanghai',
    app_blacklist    => ['impala', 'rdbms', 'search', 'spark', 'sqoop'],
    ssl_private_key  => false,
    ssl_certificate  => false
  }

  class { 'cdh::hbase::master':
    version => $hadoop::params::hbase_version
  }
}

class my::hadoop::worker inherits hadoop::base {
  include hadoop::params
  include cdh::hadoop::worker
  include cdh::pig
  include cdh::sqoop

  class { 'zookeeper':
    hosts    => {
      'vm-cdh-cluster-dn1.example.com' => 1,
      'vm-cdh-cluster-dn2.example.com' => 2,
      'vm-cdh-cluster-dn3.example.com' => 3
    },
    data_dir => '/var/lib/zookeeper'
  }
  include zookeeper::server

  class { 'cdh::hbase::slave':
    version => $hadoop::params::hbase_version
  }
}

node 'vm-cdh-cluster-nn1.example.com' {
  include my::hadoop::master
}

node 'vm-cdh-cluster-nn2.example.com' {
}

node /vm-cdh-cluster-dn\d+.example.com/ {
  include my::hadoop::worker
}

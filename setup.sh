#!/bin/bash

if [ "$(id -u)" -ne 0 ]
  then echo "Please run as root"
  exit
fi

#setup tap0 interface
if ! grep -q "/tap0" /etc/network/interfaces; then
    echo "
    auto tap0
    iface tap0 inet manual
    pre-up ip tuntap add tap0 mode tap user root
    pre-up ip link set tap0 address 0e:74:01:4f:74:8a
    pre-up ip addr add 192.168.100.1/24 dev tap0
    up ip link set dev tap0 up
    post-up ip route del 192.168.100.0/24 dev tap0
    post-up ip route add 192.168.100.0/24 dev tap0
    post-down ip link del dev tap0" >> /etc/network/interfaces
    service networking restart
fi

#copy armx to /
if [ ! -d "/armx" ]; then
    cp -r "$(pwd)" /
fi

#setup nfs-kernel-server
apt-get update
apt-get install nfs-kernel-server -y
if ! grep -q "/armx" /etc/exports; then
    echo "/armx             192.168.100.0/24(rw,sync,no_subtree_check)" >> /etc/exports
fi
cd /armx/hostfs
unzip hostfs.ext2.zip
chown -R nobody:nogroup /armx
exportfs -a
service nfs-kernel-server restart

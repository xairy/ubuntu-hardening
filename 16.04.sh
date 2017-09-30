#!/bin/bash

set -e

echo "[*] automated script to secure your Ubuntu 16.04.
    It's recommended to have a look at the current script's commands to understand what will be affected."

if ! [ $(id -u) = 0 ]; then
   echo "[-] Please run as super user."
   exit 1
fi

echo "[ ] Checking unneeded services.."

if systemctl -q is-active cups.service;then
  echo "[ ] Disabling/stopping cups service (Common UNIX Printing System)//"
  systemctl disable cups.socket cups.path cups.service
  systemctl kill --signal=SIGKILL cups.service
  systemctl stop cups.socket cups.path
  systemctl disable cups-browsed
  systemctl stop cups-browsed
  echo "[+] Done"
fi

if systemctl -q is-active avahi-daemon.service;then
  echo "[ ] Disabling/stopping avahi-daemon service (system for multicast DNS/DNS-SD service discovery)//"
  systemctl disable avahi-daemon.socket avahi-daemon.service
  systemctl stop avahi-daemon.socket avahi-daemon.service
fi

echo "[ ] Restricting information exposed by the kernel.."
echo "-- Disable system log being visible to anybody"
echo "-- Disable kernel pointers being shown"
echo "-- Disable unprivileged user namespaces"
echo "-- Disable unwanted incoming packets"
echo "-- Disable IPv6"
echo "-- Do not accept ICMP redirects (prevent MITM (man-in-the-middle) attacks)"
echo "-- Do not send ICMP redirects (we are not a router)"
echo "-- Do not accept IP source route packets (we are not a router)"
echo "-- Log Martian Packets"
echo "-- Ignore ICMP broadcasts"
echo "-- Disable LightDM guest sessions"

cat <<EOF >> /etc/systctl.conf
######################## Ubuntu Hardening
# Disable system log being visible to anybody
kernel.dmesg_restrict = 1
# Disable kernel pointers being shown
kernel.kptr_restrict = 2
# Disable unprivileged user namespaces
kernel.unprivileged_userns_clone = 0
# Disable IPv6
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
# Do not accept ICMP redirects (prevent MITM (man-in-the-middle) attacks)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
# Do not send ICMP redirects (we are not a router)
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
# Do not accept IP source route packets (we are not a router)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
# Log Martian Packets
net.ipv4.conf.all.log_martians = 1
# Ignore ICMP broadcasts.
net.ipv4.icmp_echo_ignore_broadcasts = 1
EOF

sysctl -p

ufw enable
ufw default deny incoming

sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1 quiet splash"/' /etc/default/grub

update-grub2

cat <<EOF >> /etc/lightdm/lightdm.conf.d/50-no-guest.conf
[Seat:*]
allow-guest=false
EOF

while true; do
    read -p "[+] Done. You need to reboot your system. Reboot?" yn
    case $yn in
        [Yy]* ) shutdown -r now; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

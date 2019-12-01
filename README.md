# ubuntu-hardening

Some random simple tips on how to improve security of an Ubuntu Desktop installation. 
The instructions are based on Ubuntu 16.04.2 (and Linux Mint 18.1).
I definitely recommend reading up on each step yourself instead of just blindly following them.

## Set BIOS/UEFI password

Enable and set BIOS/UEFI password.
The exact steps for this depend on the particular hardware and firmware that you have.
Google it.

## Enable full disk encryption

During installation select the checkbox `Encrypt the new Ubuntu installation for security`.

## Update packages

``` bash
sudo apt-get update && sudo apt-get dist-upgrade
```

## Set Grub password

Generate password hash:
``` bash
$ grub-mkpasswd-pbkdf2
Enter password: 
Reenter password: 
PBKDF2 hash of your password is grub.pbkdf2.sha512.10000.06FF[...]
```

Add the following lines to `etc/grub.d/40_custom`:
``` bash
$ cat etc/grub.d/40_custom
...
set superusers="root"
password_pbkdf2 root grub.pbkdf2.sha512.10000.06FF[...]
```

Regenerate grub config:
``` bash
sudo update-grub2
```

Now reboot.

## Disable unneeded services

By default Ubuntu enables and starts a few services that listen on external network:
``` bash
$ sudo netstat -tulpn
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 127.0.0.1:631           0.0.0.0:*               LISTEN      856/cupsd       
tcp        0      0 127.0.1.1:53            0.0.0.0:*               LISTEN      1050/dnsmasq    
tcp6       0      0 ::1:631                 :::*                    LISTEN      856/cupsd       
udp        0      0 0.0.0.0:47622           0.0.0.0:*                           1050/dnsmasq    
udp        0      0 0.0.0.0:33349           0.0.0.0:*                           855/avahi-daemon: r
udp        0      0 0.0.0.0:631             0.0.0.0:*                           993/cups-browsed
udp        0      0 0.0.0.0:5353            0.0.0.0:*                           855/avahi-daemon: r
udp        0      0 127.0.1.1:53            0.0.0.0:*                           1050/dnsmasq    
udp        0      0 0.0.0.0:68              0.0.0.0:*                           1038/dhclient   
udp6       0      0 :::39773                :::*                                855/avahi-daemon: r
udp6       0      0 :::5353                 :::*                                855/avahi-daemon: r
```

Disable `cupsd`:
``` bash
sudo systemctl disable cups.socket cups.path cups.service
sudo systemctl kill --signal=SIGKILL cups.service
sudo systemctl stop cups.socket cups.path
```

Disable `cups-browsed`:
``` bash
sudo systemctl disable cups-browsed
sudo systemctl stop cups-browsed
```

Disable `avahi-daemon`:
``` bash
sudo systemctl disable avahi-daemon.socket avahi-daemon.service
sudo systemctl stop avahi-daemon.socket avahi-daemon.service
```

For Linux Mint disable `ntp`:
```
sudo systemctl stop ntp
sudo systemctl disable ntp
```

Now reboot and make sure these services are not running.

## Restrict information exposed by the kernel

Add the following lines to `/etc/sysctl.conf`.

Disable system log being visible to anybody:
```
kernel.dmesg_restrict=1
```

Run `sudo sysctl -p` after adding settings to `/etc/sysctl.conf` here and below.

Check:
``` bash
$ dmesg
dmesg: read kernel buffer failed: Operation not permitted
```

Disable kernel pointers being shown:
```
kernel.kptr_restrict=2
```

Check:
``` bash
$ sudo cat /proc/kallsyms
0000000000000000 A irq_stack_union
0000000000000000 A __per_cpu_start
0000000000000000 A exception_stacks
0000000000000000 A gdt_page
0000000000000000 A espfix_waddr
0000000000000000 A espfix_stack
...
```

## Disable unprivileged user namespaces

This significantly reduces kernel attack surface.

Add this line `/etc/sysctl.conf`:
```
kernel.unprivileged_userns_clone=0
```

Check:
``` bash
$ unshare -U
unshare: unshare failed: Operation not permitted
```

## Disable unprivileged BPF

Add this line `/etc/sysctl.conf`:
```
kernel.unprivileged_bpf_disabled=1
```

## Enable firewall

Disable unwanted incoming packets:
``` bash
sudo ufw enable
sudo ufw default deny incoming
```

## Disable IPv6

Add these lines to `/etc/sysctl.conf`:
``` bash
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1  
net.ipv6.conf.lo.disable_ipv6=1
```

Change `/etc/default/grub` as:
``` bash
...
GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1 quiet splash"
...
```

Update Grub config:
``` bash
sudo update-grub2
```

Now reboot.

Make sure that you don't see `inet6` address in `ifconfig`:
``` bash
ifconfig | grep inet6
```

## Disable LightDM guest sessions

Not required on Linux Mint.

Create `/etc/lightdm/lightdm.conf.d/50-no-guest.conf` file with the following content:
```
$ cat /etc/lightdm/lightdm.conf.d/50-no-guest.conf
[Seat:*]
allow-guest=false
```

Now reboot.

Make sure login as guest is not available on the login screen.

## More

Other things you can do.

- Whitelist kernel modules
- Whitelist USB devices
- Custom kernel / grsecurity
- AppArmor / SELinux

#!/bin/sh
export LANG="en_US.UTF-8"
export LANGUAGE=en_US:en
export LC_NUMERIC="C"
export LC_CTYPE="C"
export LC_MESSAGES="C"
export LC_ALL="C"

apk update
# Base system
apk add --no-cache openrc bash
apk add --no-cache alpine-base
apk add --no-cache util-linux
apk add --no-cache nano
apk add --no-cache vim
apk add --no-cache tzdata
apk add --no-cache ca-certificates
update-ca-certificates
# Basic services
rc-update add bootmisc boot
rc-update add syslog default
rc-update add crond default

# enable networking
apk add --no-cache dhcpcd
apk add --no-cache wpa_supplicant
apk add --no-cache wireless-tools
apk add --no-cache iw
rc-update add networking default
rc-update add wpa_supplicant default

# enable ssh server
apk add --no-cache openssh
rc-update add sshd default
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config || true

# enable X11 minimal
apk add --no-cache xterm
apk add --no-cache \
    xorg-server \
    xinit \
    xrandr \
    xset \
    xf86-input-libinput \
    mesa-dri-gallium \
    mesa-egl \
    mesa-gl \
    dbus \
    eudev

# Python minimal
apk add --no-cache \
    python3 \
    py3-pip

# enable serial console
echo "ttyFIQ0::respawn:/sbin/agetty -L 1500000 ttyFIQ0 vt100" >> /etc/inittab
echo "ttyFIQ0" >> /etc/securetty

# root password
echo "root:fa" | chpasswd

echo "$(date +%Y%m%d)" > /etc/rom-version
[ -e /lib/firmware ] || mkdir -p /lib/firmware
[ -e /lib/modules ] || mkdir -p /lib/modules

# Set hostname
echo "alpine" > /etc/hostname
cat << 'EOL' > /etc/hosts
127.0.0.1       alpine.my.domain alpine localhost.localdomain localhost
::1             localhost localhost.localdomain
EOL

# Set up mirror
cat << 'EOL' > /etc/apk/repositories
http://mirrors.aliyun.com/alpine/v3.23/main
http://mirrors.aliyun.com/alpine/v3.23/community
EOL

# run setup-alpine quick mode
cat << 'EOL' > /answer_file
# Use US layout with US variant
KEYMAPOPTS="us us"

# Contents of /etc/network/interfaces
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    hostname alpine
"

# Set timezone to UTC
TIMEZONEOPTS="-z UTC"

# Add a random mirror
APKREPOSOPTS="-r"

# Install Openssh
SSHDOPTS="-c openssh"

# Use openntpd
NTPOPTS="-c openntpd"
EOL
setup-alpine -q -f /answer_file
rm -f /answer_file

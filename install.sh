#!/bin/bash
#
# About: Upgrade CentOS 7 to 8 automatically
# Author: johnj, liberodark
# License: GNU GPLv3

version="0.0.1"

echo "Welcome on CenOS Upgrade Install Script $version"

#=================================================
# CHECK ROOT
#=================================================

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

#=================================================
# RETRIEVE ARGUMENTS FROM THE MANIFEST AND VAR
#=================================================

distribution=$(cat /etc/*release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/["]//g' | awk '{print $1}')

function info() {
  echo "[$(date)] [info] $1"
}

function preflight_check() {
  echo -n "[preflight] checking $1"
  if [[ $2 -eq 0 ]]; then
    echo " ... PASSED"
  else
    echo " ... FAILED ($3)"
    exit 1
  fi
}

test "$(grep VERSION_ID /etc/os-release | awk -F'=' '{ print $2 }')" == '"7"'
preflight_check "if you are running this on a RHEL-like 7 system" $? "you need to run me from a RHEL-like 7 OS"

available=$(df --total $STAGING_DIR | tail -n1 | awk '{ print $4 }')
test "$((available))" -ge 2000000
preflight_check "if you have at least 2GB in the staging directory (${STAGING_DIR}), you can override this by setting the env var STAGING_DIR (ie, STAGING_DIR='/var/to8' $0)" $? "you need at least 2GB of free space to run me"

echo
echo "Preflight checks PASSED"
echo

setenforce 0

echo "8" > /etc/yum/vars/releasever

# these will be replaced by dnf symlinks
mkdir -p $STAGING_DIR/etc/yum/yum7
mv /etc/yum/{pluginconf.d,protected.d,vars} $STAGING_DIR/etc/yum/yum7

# from https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
# more info: https://www.centos.org/keys/

# pub  4096R/8483C65D 2019-05-03 CentOS (CentOS Official Signing Key) <security@centos.org>
#        Key fingerprint = 99DB 70FA E1D7 CE22 7FB6  4882 05B5 55B3 8483 C65D
cat >/etc/pki/rpm-gpg/RPM-GPG-KEY-8 <<EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2.0.22 (GNU/Linux)

mQINBFzMWxkBEADHrskpBgN9OphmhRkc7P/YrsAGSvvl7kfu+e9KAaU6f5MeAVyn
rIoM43syyGkgFyWgjZM8/rur7EMPY2yt+2q/1ZfLVCRn9856JqTIq0XRpDUe4nKQ
8BlA7wDVZoSDxUZkSuTIyExbDf0cpw89Tcf62Mxmi8jh74vRlPy1PgjWL5494b3X
5fxDidH4bqPZyxTBqPrUFuo+EfUVEqiGF94Ppq6ZUvrBGOVo1V1+Ifm9CGEK597c
aevcGc1RFlgxIgN84UpuDjPR9/zSndwJ7XsXYvZ6HXcKGagRKsfYDWGPkA5cOL/e
f+yObOnC43yPUvpggQ4KaNJ6+SMTZOKikM8yciyBwLqwrjo8FlJgkv8Vfag/2UR7
JINbyqHHoLUhQ2m6HXSwK4YjtwidF9EUkaBZWrrskYR3IRZLXlWqeOi/+ezYOW0m
vufrkcvsh+TKlVVnuwmEPjJ8mwUSpsLdfPJo1DHsd8FS03SCKPaXFdD7ePfEjiYk
nHpQaKE01aWVSLUiygn7F7rYemGqV9Vt7tBw5pz0vqSC72a5E3zFzIIuHx6aANry
Gat3aqU3qtBXOrA/dPkX9cWE+UR5wo/A2UdKJZLlGhM2WRJ3ltmGT48V9CeS6N9Y
m4CKdzvg7EWjlTlFrd/8WJ2KoqOE9leDPeXRPncubJfJ6LLIHyG09h9kKQARAQAB
tDpDZW50T1MgKENlbnRPUyBPZmZpY2lhbCBTaWduaW5nIEtleSkgPHNlY3VyaXR5
QGNlbnRvcy5vcmc+iQI3BBMBAgAhBQJczFsZAhsDBgsJCAcDAgYVCAIJCgsDFgIB
Ah4BAheAAAoJEAW1VbOEg8ZdjOsP/2ygSxH9jqffOU9SKyJDlraL2gIutqZ3B8pl
Gy/Qnb9QD1EJVb4ZxOEhcY2W9VJfIpnf3yBuAto7zvKe/G1nxH4Bt6WTJQCkUjcs
N3qPWsx1VslsAEz7bXGiHym6Ay4xF28bQ9XYIokIQXd0T2rD3/lNGxNtORZ2bKjD
vOzYzvh2idUIY1DgGWJ11gtHFIA9CvHcW+SMPEhkcKZJAO51ayFBqTSSpiorVwTq
a0cB+cgmCQOI4/MY+kIvzoexfG7xhkUqe0wxmph9RQQxlTbNQDCdaxSgwbF2T+gw
byaDvkS4xtR6Soj7BKjKAmcnf5fn4C5Or0KLUqMzBtDMbfQQihn62iZJN6ZZ/4dg
q4HTqyVpyuzMXsFpJ9L/FqH2DJ4exGGpBv00ba/Zauy7GsqOc5PnNBsYaHCply0X
407DRx51t9YwYI/ttValuehq9+gRJpOTTKp6AjZn/a5Yt3h6jDgpNfM/EyLFIY9z
V6CXqQQ/8JRvaik/JsGCf+eeLZOw4koIjZGEAg04iuyNTjhx0e/QHEVcYAqNLhXG
rCTTbCn3NSUO9qxEXC+K/1m1kaXoCGA0UWlVGZ1JSifbbMx0yxq/brpEZPUYm+32
o8XfbocBWljFUJ+6aljTvZ3LQLKTSPW7TFO+GXycAOmCGhlXh2tlc6iTc41PACqy
yy+mHmSv
=kkH7
-----END PGP PUBLIC KEY BLOCK-----
EOF

cat > /etc/yum.repos.d/CentOS-Base.repo <<EOF
[BaseOS]
name=CentOS-8 - Base
mirrorlist=http://mirrorlist.centos.org/?release=8&arch=\$basearch&repo=BaseOS&infra=\$infra
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-8
EOF

cat > /etc/yum.repos.d/CentOS-AppStream.repo <<EOF
[AppStream]
name=CentOS-8 - AppStream
mirrorlist=http://mirrorlist.centos.org/?release=8&arch=\$basearch&repo=AppStream&infra=\$infra
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-8
EOF

cat > /etc/yum.repos.d/CentOS-Extras.repo <<EOF
[Extras]
name=CentOS-8 - Extras
mirrorlist=http://mirrorlist.centos.org/?release=8&arch=\$basearch&repo=Extras&infra=\$infra
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-8
EOF

info "starting CentOS 8 setup"
yum install -y kernel kernel-core kernel-modules
#yum install -y dnf dnf-utils --skip-broken
#dnf install -y hostname yum centos-release glibc-langpack-en $(rpmquery -a --queryformat '%{NAME} ') &> /dev/null
info "finished CentOS 8 setup"

#info "beginning to sync ${STAGING_DIR} to /"
#rsync -irazvAX --progress --backup --backup-dir=$STAGING_DIR/to8_backup_$(date +\%Y-\%m-\%d) $STAGING_DIR/* / --exclude="var/cache/yum/x86_64/8/BaseOS/packages" --exclude="tmp" --exclude="sys" --exclude="lost+found" --exclude="mnt" --exclude="proc" --exclude="dev" --exclude="media" --exclude="to8.yum.log"  &> /dev/null
#info "finished syncing ${STAGING_DIR} to /"

#info "refreshing grub config for /boot"
#grub2-mkconfig -o /boot/grub2/grub.cfg &> /dev/null
#info "grub config reload for /boot finished"

#info "setting up new repo files"
#for f in `ls /etc/yum.repos.d/CentOS*.repo.rpmnew`; do
#  n=$(echo $f | sed -e 's/\.rpmnew$//')
#  mv -vf $f $n
#done

#if [ -e /etc/os-release.rpmnew ]; then
#  mv /etc/os-release /etc/os-release.rpmold
#  mv /etc/os-release.rpmnew /etc/os-release
#fi

# this locale reference seems to have changed in 8
#if [[ "$LANG" == "en_US.UTF-8" ]]; then
#  localectl set-locale en_US.utf8 &> /dev/null
#fi

#systemctl daemon-reload &> /dev/null

#yum install --enablerepo="extras" centos-release-stream

#!/bin/bash

echo '- Upgrade all packages (if needed):'
apt update && apt dist-upgrade && apt autoremove && apt autoclean
echo '- Upgrade completed'
echo ''
echo '- Install prerequisites packages:'
apt install -y $APT_PACKAGES
echo '- Prerequisites installed'
echo ''
echo '- Install Veracrypt:'
rm veracrypt-console-1.24-Update4-Ubuntu-18.04-amd64.deb
wget -O /tmp/veracrypt-console-1.24-Update4-Ubuntu-18.04-amd64.deb 'https://launchpad.net/veracrypt/trunk/1.24-update4/+download/veracrypt-console-1.24-Update4-Ubuntu-18.04-amd64.deb' && dpkg -i /tmp/veracrypt-console-1.24-Update4-Ubuntu-18.04-amd64.deb
echo ''

echo '- Looking for the latest backup done:'
LATEST_BACKUP=$(curl -u $FTP_ACCESS ftp://$FTP_HOST/ 2>/dev/null | tail -1 | awk '{print $(NF)}')
echo '- Latest backup found: '$LATEST_BACKUP
rm -rf $PATH_BACKUP/$LATEST_BACKUP
mkdir $PATH_BACKUP/$LATEST_BACKUP
echo ''

echo '- Download the latest backup:'
curl -u $FTP_ACCESS ftp://$FTP_HOST/$LATEST_BACKUP --output $PATH_BACKUP/$LATEST_BACKUP/$LATEST_BACKUP.gpg
echo '- Download finished'

echo '- Uncrypt the latest backup:'
gpg --batch -v --passphrase "$GPG_PASSPHRASE" --output $PATH_BACKUP/$LATEST_BACKUP/$LATEST_BACKUP.tar.gz --decrypt $PATH_BACKUP/$LATEST_BACKUP/$LATEST_BACKUP.gpg && rm $PATH_BACKUP/$LATEST_BACKUP/$LATEST_BACKUP.gpg
echo '- Uncrypt all files'
echo ''

echo '- Uncompress the backup:'
tar xzvf $PATH_BACKUP/$LATEST_BACKUP/$LATEST_BACKUP.tar.gz -C $PATH_BACKUP/$LATEST_BACKUP && rm $PATH_BACKUP/$LATEST_BACKUP/$LATEST_BACKUP.tar.gz
echo '- Uncompress done'
echo ''

echo '- restore files in origin path'
rsync -aAXvhx --exclude={"$ENCLAVE_DIR/*"} $PATH_BACKUP/$LATEST_BACKUP/opt /
rsync -aAXvhx $PATH_BACKUP/$LATEST_BACKUP/root /
echo 'restoration done'
echo ''

echo '- Disable the swap'
swapoff -a
systemctl mask swapfile.swap
rm /swapfile
sed -E -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab
echo ''

echo '- Disable IPv6'
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sysctl -w net.ipv6.conf.enp1s0.disable_ipv6=1
sed -i -E 's/GRUB_CMDLINE_LINUX="(.*)"/GRUB_CMDLINE_LINUX="\1 ipv6.disable=1"/' /etc/default/grub
sed -i -E 's/GRUB_CMDLINE_LINUX_DEFAULT="(.*)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 ipv6.disable=1"/' /etc/default/grub
update-grub

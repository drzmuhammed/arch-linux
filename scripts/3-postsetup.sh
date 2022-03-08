#!/usr/bin/env bash

source ${HOME}/arch-linux/configs/setup.conf

echo -ne "
-------------------------------------------------------------------------
            CONFIGURING UFW FIREWALL
-------------------------------------------------------------------------
"

ufw disable
ufw default deny incoming
ufw default allow outgoing
ufw allow 853/tcp
ufw allow 853/udp
ufw allow 443/tcp
ufw allow 443/udp
ufw enable

echo -ne "
-------------------------------------------------------------------------
            Enabling Essential Services
-------------------------------------------------------------------------

"
echo -ne "
enabling acpid.service
"
systemctl enable --now acpid
echo -ne "
enabling  apparmor.service
"
systemctl enable --now apparmor
echo -ne " 
enabling  auditd.service
"
systemctl enable --now auditd
echo -ne "
enabling  bluetooth.service
"
systemctl enable --now bluetooth
echo -ne "
enabling  cpupower.service
"
systemctl enable --now cpupower

echo -ne "
enabling  fail2ban.service
"
systemctl enable --now fail2ban

echo -ne "  
enabling  fstrim.timer
"
systemctl enable fstrim.timer

echo -ne "  
enabling  NetworkManager.service
"
systemctl enable --now NetworkManager

echo -ne "  
enabling reflector.timer
"
systemctl enable --now reflector.timer

echo -ne "  
enabling systemd-remount-fs.service
"
systemctl enable --now systemd-remount-fs

echo -ne "  
enabling  systemd-resolved.service
"
systemctl enable --now systemd-resolved

echo -ne "  
enabling  systemd-timesyncd.service
"
systemctl enable --now systemd-timesyncd

echo -ne "  
enabling  thermald.service
"
systemctl enable --now thermald

echo -ne "  
enabling  tlp.service
"
systemctl enable --now tlp

echo -ne "  
enabling  ufw.service
"
systemctl enable --now ufw

echo -ne "
-------------------------------------------------------------------------
            Creating Snapper Config
-------------------------------------------------------------------------
"

SNAPPER_CONF="$HOME/arch-linux/configs/etc/snapper/configs/root"
mkdir -p /etc/snapper/configs/
cp -rfv ${SNAPPER_CONF} /etc/snapper/configs/

SNAPPER_CONF_D="$HOME/arch-linux/configs/etc/conf.d/snapper"
mkdir -p /etc/conf.d/
cp -rfv ${SNAPPER_CONF_D} /etc/conf.d/

rm -r $HOME/arch-linux
rm -r /home/$USERNAME/arch-linux

# Replace in the same state
cd $pwd

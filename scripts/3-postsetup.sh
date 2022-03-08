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

su $USERNAME
echo -ne "
-------------------------------------------------------------------------
            INSTALLING AUR HELPER
-------------------------------------------------------------------------
"
if [[ ! $AUR_HELPER == none ]]; then
  cd ~
  git clone "https://aur.archlinux.org/$AUR_HELPER.git"
  cd ~/$AUR_HELPER
  makepkg -si --noconfirm
  $AUR_HELPER -S --noconfirm --needed $(cat $PKGS_DIR/base-aur)
else
  echo "aur helper not installed because you havent selected any" 
fi

$PASSWORD | su

echo -ne "
-------------------------------------------------------------------------
            Creating Snapper Config
-------------------------------------------------------------------------
"

mkdir -p /etc/snapper/configs/
cp -rfv $HOME/arch-linux/configs/root /etc/snapper/configs/

mkdir -p /etc/conf.d/
cp -rfv $HOME/arch-linux/configs/snapper /etc/conf.d/

rm -r $HOME/arch-linux
rm -r /home/$USERNAME/arch-linux

# Replace in the same state
cd $pwd

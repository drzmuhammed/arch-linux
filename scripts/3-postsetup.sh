#!/usr/bin/env bash

source ${HOME}/arch-linux/configs/setup.conf

echo -ne"
-------------------------------------------------------------------------
                    Adding User
-------------------------------------------------------------------------
"
if [ $(whoami) = "root"  ]; then
    useradd -m -G wheel -s /bin/bash $USERNAME 
    echo "$USERNAME created, home directory created, added to wheel group, default shell set to /bin/bash"

# use chpasswd to enter $USERNAME:$password
    echo "$USERNAME:$PASSWORD" | chpasswd
    echo "$USERNAME password set"

    cp -R $HOME/arch-linux /home/$USERNAME/
    chown -R $USERNAME: /home/$USERNAME/arch-linux
    echo "arch-linux copied to home directory"


else
	echo "You are already a user proceed with  installs"
fi

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
systemctl enable acpid
echo -ne "
enabling  apparmor.service
"
systemctl enable apparmor
echo -ne " 
enabling  auditd.service
"
systemctl enable auditd
echo -ne "
enabling  bluetooth.service
"
systemctl enable bluetooth
echo -ne "
enabling  cpupower.service
"
systemctl enable cpupower

echo -ne "
enabling  fail2ban.service
"
systemctl enable fail2ban

echo -ne "  
enabling  fstrim.timer
"
systemctl enable fstrim.timer

echo -ne "  
enabling  NetworkManager.service
"
systemctl enable NetworkManager

echo -ne "  
enabling reflector.timer
"
systemctl enable reflector.timer

echo -ne "  
enabling systemd-remount-fs.service
"
systemctl enable systemd-remount-fs

echo -ne "  
enabling  systemd-resolved.service
"
systemctl enable systemd-resolved

echo -ne "  
enabling  systemd-timesyncd.service
"
systemctl enable systemd-timesyncd

echo -ne "  
enabling  thermald.service
"
systemctl enable thermald

echo -ne "  
enabling  tlp.service
"
systemctl enable tlp

echo -ne "  
enabling  ufw.service
"
systemctl enable ufw


timedatectl --no-ask-password set-timezone ${TIME_ZONE}
timedatectl --no-ask-password set-ntp 1

echo -ne "
-------------------------------------------------------------------------
            Creating Snapper Config
-------------------------------------------------------------------------
"

mkdir -p /etc/snapper/configs/
cp -rfv $HOME/arch-linux/configs/root /etc/snapper/configs/

mkdir -p /etc/conf.d/
cp -rfv $HOME/arch-linux/configs/snapper /etc/conf.d/

echo -ne "
-------------------------------------------------------------------------
            Configuring Sudo Rights
-------------------------------------------------------------------------
"
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

echo -ne "
-------------------------------------------------------------------------
            Removing Arch Linux Setup Files
-------------------------------------------------------------------------
"
rm -r $HOME/arch-linux
rm -r /home/$USERNAME/arch-linux
# Replace in the same state
cd $pwd

#!/usr/bin/env bash

source $HOME/arch-linux/configs/setup.conf

echo -ne "

-------------------------------------------------------------------------
                setting place and local time
-------------------------------------------------------------------------

"
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime

echo -ne "

-------------------------------------------------------------------------
                syncing harware clock
-------------------------------------------------------------------------

"
hwclock --systohc
echo -ne "

-------------------------------------------------------------------------
               generating locale
-------------------------------------------------------------------------

"
sed 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo -ne "

-------------------------------------------------------------------------
               setting language and keyboard layout
-------------------------------------------------------------------------

"
echo -ne "LANG=en_US.UTF-8" >> /etc/locale.conf
echo -ne "us" >> /etc/vconsole.conf
echo -ne "

-------------------------------------------------------------------------
               setting machine name and hostname
-------------------------------------------------------------------------

"
echo -ne "${machine_name}" >> /etc/hostname
echo -ne "127.0.0.1 localhost" >> /etc/hosts
echo -ne "::1       localhost" >> /etc/hosts
echo -ne "127.0.1.1 ${machine_name}.localdomain ${machine_name}" >> /etc/hosts

echo -ne "

-------------------------------------------------------------------------
               set root password
-------------------------------------------------------------------------

"
passwd


echo -ne "

-------------------------------------------------------------------------
             installing core linux packages
-------------------------------------------------------------------------

"
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -Sy --noconfirm --needed
pacman -S --noconfirm --needed - < $PKGS_DIR/base-pacman

echo -ne "

-------------------------------------------------------------------------
             installing and configuring grub
-------------------------------------------------------------------------

"
sed 's/^MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
sed 's/^HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect keyboard modconf block encrypt filesystems resume fsck)/' /etc/mkinitcpio.conf
mkinitcpio -p linux
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
ENCRYPTED_PARTITION_UUID=$(cat setup.conf)
sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:cryptedsda2 root=/dev/mapper/cryptedsda2 %g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -p linux

echo -ne "

-------------------------------------------------------------------------
                            configuring swap
-------------------------------------------------------------------------

"
touch swap/swapfile
truncate -s 0 ./swap/swapfile
chattr +C ./swap/swapfile
btrfs property set ./swap/swapfile compression none
dd if=/dev/zero of=/swap/swapfile bs=1M count=8192
mkswap /swap/swapfile
chmod 600 /swap/swapfile
swapon /swap/swapfile lo
echo -ne "/swap/swapfile none swap defaults 0 0" >> /etc/fstab

echo -ne "
-------------------------------------------------------------------------
                            configuring firewall
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

sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

umount -a

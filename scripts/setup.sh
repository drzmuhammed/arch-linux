#!/bin/bash
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
pacman -S --needed - < $PKGS_DIR/base-pacman

echo -ne "

-------------------------------------------------------------------------
             installing and configuring grub
-------------------------------------------------------------------------

"
sed 's/MODULES=()/MODULES=(btrfs)/g' /etc/mkinitcpio.conf
sed 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect keyboard modconf block encrypt filesystems resume fsck)/g' /etc/mkinitcpio.conf
mkinitcpio -p linux
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:cryptedsda2 root=/dev/mapper/cryptedsda2 %g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg



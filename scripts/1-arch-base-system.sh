#!/bin/bash
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "us" >> /etc/vconsole.conf
echo "${machine_name}" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 ${machine_name}.localdomain ${machine_name}" >> /etc/hosts


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
#sed
#mkinitcpio -p linux
#grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
#grub-mkconfig -o /boot/grub/grub.cfg
#sed
#grub-mkconfig -o /boot/grub/grub.cfg


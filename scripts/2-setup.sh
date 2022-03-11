#!/usr/bin/env bash

source /arch-install/arch-linux/configs/setup.conf

echo -ne "
setting up place and local time
"
ln -sf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime

echo -ne "
syncing harware clock
"
hwclock --systohc

echo -ne "
generating locale
"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo -ne "
setting language and keyboard layout
"
echo -ne "LANG=en_US.UTF-8" >> /etc/locale.conf
echo -ne "KEYMAP=us" >> /etc/vconsole.conf

echo -ne "
setting host name
"
echo $NAME_OF_MACHINE > /etc/hostname
echo -ne "127.0.0.1 localhost" >> /etc/hosts
echo -ne "::1       localhost" >> /etc/hosts
echo -ne "127.0.1.1 $NAME_OF_MACHINE.localdomain $NAME_OF_MACHINE" >> /etc/hosts


echo -ne "
-------------------------------------------------------------------------
            INSTALLING ARCH LINUX CORE PACKAGES
-------------------------------------------------------------------------
"
pacman -Syu --noconfirm --needed
pacman -S --noconfirm --needed $(cat $PKGS_DIR/base-pacman)

echo -ne "
-------------------------------------------------------------------------
            Installing Microcode
-------------------------------------------------------------------------
"

# determine processor type and install microcode
proc_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${proc_type}; then
    echo "Installing Intel microcode"
    pacman -S --noconfirm --needed intel-ucode
    proc_ucode=intel-ucode.img
elif grep -E "AuthenticAMD" <<< ${proc_type}; then
    echo "Installing AMD microcode"
    pacman -S --noconfirm --needed amd-ucode
    proc_ucode=amd-ucode.img
fi

echo -ne "
-------------------------------------------------------------------------
            SETTING UP ENCRYPTED SWAP
-------------------------------------------------------------------------
"

touch /swap/swapfile
truncate -s 0 /swap/swapfile
chattr +C /swap/swapfile
btrfs property set /swap/swapfile compression none
dd if=/dev/zero of=/swap/swapfile bs=1M count=8192
chmod 600 /swap/swapfile
mkswap /swap/swapfile
swapon /swap/swapfile

echo -ne "/swap/swapfile none swap defaults 0 0" >> /etc/fstab
echo -ne "
-------------------------------------------------------------------------
            SETTING UP ROOT PASSWORD
-------------------------------------------------------------------------
"
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << PASSWD_CMDS  | passwd
${ROOT_PASSWORD}
${ROOT_PASSWORD}
PASSWD_CMDS

echo -ne "
-------------------------------------------------------------------------
            SETTING UP GRUB
-------------------------------------------------------------------------
"

sed -i 's/^MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
sed -i 's/^HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect keyboard modconf block encrypt filesystems resume fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:cryptedsda2 root=/dev/mapper/cryptedsda2 %g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P 

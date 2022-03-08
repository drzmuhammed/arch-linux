#!/usr/bin/env bash

source $HOME/arch-linux/configs/setup.conf

echo -ne "
setting up place and local time
"
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

echo -ne "
syncing harware clock
"
hwclock --systohc
timedatectl --no-ask-password set-timezone ${TIMEZONE}
timedatectl --no-ask-password set-ntp 1

echo -ne "
generating locale
"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo -ne "
setting language and keyboard layout
"
echo -ne "LANG=en_US.UTF-8" >> /etc/locale.conf
echo -ne "us" >> /etc/vconsole.conf

echo -ne "
-------------------------------------------------------------------------
            SET SYSTEM ROOT PASSWORD
-------------------------------------------------------------------------
"

passwd

echo -ne "
-------------------------------------------------------------------------
            INSTALLING ARCH LINUX CORE PACKAGES
-------------------------------------------------------------------------
"
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -Sy --noconfirm --needed
pacman -S --noconfirm --needed $(cat $PKGS_DIR/base-pacman)

echo -ne "
-------------------------------------------------------------------------
            SETTING UP ENCRYPTED SWAP
-------------------------------------------------------------------------
"

cd swap
touch swapfile
truncate -s 0 ./swapfile
chattr +C ./swapfile
btrfs property set ./swapfile compression none
dd if=/dev/zero of=/swapfile bs=1M count=8192
mkswap /swapfile
chmod 640 /swapfile
swapon /swapfile
cd
echo -ne "/swap/swapfile none swap defaults 0 0" >> /etc/fstab

echo -ne "
-------------------------------------------------------------------------
            SETTING UP GRUB
-------------------------------------------------------------------------
"

sed -i 's/^MODULES=()/MODULES=(btrfs)/' /etc/mkinitcpio.conf
sed -i 's/^HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect keyboard modconf block encrypt filesystems resume fsck)/' /etc/mkinitcpio.conf
mkinitcpio -p linux
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:cryptedsda2 root=/dev/mapper/cryptedsda2 %g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -p linux

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
                    Installing Graphics Drivers
-------------------------------------------------------------------------
"
# Graphics Drivers find and install
gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed nvidia
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    pacman -S --noconfirm --needed xf86-video-amdgpu
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    pacman -S --needed --noconfirm mesa vulkan-intel
fi
    
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

# enter $NAME_OF_MACHINE to /etc/hostname
	echo $NAME_OF_MACHINE > /etc/hostname
else
	echo "You are already a user proceed with aur installs"
fi
echo -ne "127.0.0.1 localhost" >> /etc/hosts
echo -ne "::1       localhost" >> /etc/hosts
echo -ne "127.0.1.1 $NAME_OF_MACHINE.localdomain $NAME_OF_MACHINE" >> /etc/hosts

echo -ne "
configuring sudo rights
"
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

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

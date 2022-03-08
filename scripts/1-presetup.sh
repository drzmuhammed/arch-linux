#!/usr/bin/env bash

echo -ne "
------------------------------------------------------------------------
            PREPARING THE SYSTEM              
------------------------------------------------------------------------
"
loadkeys us
source $CONFIGS_DIR/setup.conf
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm archlinux-keyring #update keyrings to latest to prevent packages failing to install
pacman -S --noconfirm --needed pacman-contrib
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt &>/dev/null # Hiding error message if any

echo -ne "
-------------------------------------------------------------------------
            FORMATTING THE DISK
-------------------------------------------------------------------------

"
disk=$(lsblk -n --output TYPE,KNAME | awk '$1=="disk"{print "/dev/"$2}')


sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << FDISK_CMDS  | fdisk ${disk}
g      # create new GPT partition
n      # add new partition
1      # partition number
       # default - first sector 
+512MiB # partition size
n      # add new partition
2      # partition number
       # default - first sector 
       # default - last sector 
t      # change partition type
1      # partition number
1    # Linux filesystem
t      # change partition type
2      # partition number
20     # Linux filesystem
w      # write partition table and exit
FDISK_CMDS

echo -ne "

-------------------------------------------------------------------------
            CREATING LUKS BTRFS FILE SYSTEM
-------------------------------------------------------------------------

"

mkfs.fat -F32 ${disk}1
echo -n "${LUKS_PASSWORD}" | cryptsetup -y -v luksFormat ${disk}2
echo -n "${LUKS_PASSWORD}" | cryptsetup luksOpen ${disk}2 cryptedsda2
mkfs.btrfs -f /dev/mapper/cryptedsda2

# store uuid of encrypted partition for grub
echo ENCRYPTED_PARTITION_UUID=$(blkid -s UUID -o value ${disk}2) >> $CONFIGS_DIR/setup.conf

mount /dev/mapper/cryptedsda2 /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@swap
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@.snapshots

umount /mnt

mount -o noatime,compress=zstd:1,ssd,space_cache=v2,discard=async,subvol=@ /dev/mapper/cryptedsda2 /mnt

mkdir /mnt/{home,swap,var,tmp,boot,.snapshots}

mount -o noatime,compress=zstd:1,ssd,space_cache=v2,discard=async,subvol=@home /dev/mapper/cryptedsda2 /mnt/home
mount -o noatime,compress=none,ssd,space_cache=v2,discard=async,subvol=@var /dev/mapper/cryptedsda2 /mnt/var
mount -o noatime,compress=none,ssd,space_cache=v2,discard=async,subvol=@swap /dev/mapper/cryptedsda2 /mnt/swap
mount -o noatime,compress=none,ssd,space_cache=v2,discard=async,subvol=@tmp /dev/mapper/cryptedsda2 /mnt/tmp
mount -o noatime,compress=none,ssd,space_cache=v2,discard=async,subvol=@.snapshots /dev/mapper/cryptedsda2 /mnt/.snapshots
mount ${disk}1 /mnt/boot

if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi 

echo -ne "
------------------------------------------------------------------------
            INSTALLLING BARE METAL ARCH PACKAGES            
------------------------------------------------------------------------
"

pacstrap /mnt $(cat $PKGS_DIR/base-pacstrap) --noconfirm --needed
cp -R ${SCRIPT_DIR} /mnt/root/arch-linux
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

echo -ne "
------------------------------------------------------------------------
SETTING UP FILE SYSTEM TABLES         
------------------------------------------------------------------------
"
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
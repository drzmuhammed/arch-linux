#!/usr/bin/env bash

echo -ne "
------------------------------------------------------------------------
            Please select preset settings for your system              
------------------------------------------------------------------------
"
echo -ne "\n Please name your machine , this will be the host name: \n "
read machine_name
echo -ne "\n Please enter your username: \n"
read user_name
echo -ne "\n Please enter your password: \n"
read -s password # read password without echo
echo -ne "\n Please provide a username for accessing grub: \n"
read grub_username
echo -ne "\n Please provide a password for accessing grub: \n"
read -s grub_password
echo -ne "\n Please enter disk encryption password: \n"
read -s luks_password


echo -ne "
-------------------------------------------------------------------------
                    formating disk
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
83     # Linux filesystem
t      # change partition type
2      # partition number
83     # Linux filesystem
w      # write partition table and exit
FDISK_CMDS


# make filesystems
echo -ne "

-------------------------------------------------------------------------
                    creating filesystems
-------------------------------------------------------------------------

"

mkfs.fat -F32 ${disk}1
echo -n "$luks_password" | cryptsetup -y -v luksFormat ${disk}2
echo -n "$luks_password" | cryptsetup luksOpen ${disk}2 cryptedsda2
mkfs.btrfs -f /dev/mapper/cryptedsda2

# store uuid of encrypted partition for grub
    echo ENCRYPTED_PARTITION_UUID=$(blkid -s UUID -o value ${disk}2) >> $CONFIGS_DIR/setup.conf

mount /dev/mapper/cryptedsda2 /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@swap
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@snapshots

umount /mnt

mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@ /dev/mapper/cryptedsda2 /mnt

mkdir /mnt/{home,swap,var,tmp,boot,snapshots}

mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@home /dev/mapper/cryptedsda2 /mnt/home
mount -o noatime,compress=none,space_cache=v2,discard=async,subvol=@var /dev/mapper/cryptedsda2 /mnt/var
mount -o noatime,compress=none,space_cache=v2,discard=async,subvol=@swap /dev/mapper/cryptedsda2 /mnt/swap
mount -o noatime,compress=none,space_cache=v2,discard=async,subvol=@tmp /dev/mapper/cryptedsda2 /mnt/tmp
mount -o noatime,compress=none,space_cache=v2,discard=async,subvol=@snapshots /dev/mapper/cryptedsda2 /mnt/snapshots
mount ${disk}1 /mnt/boot
pacman -Sy 
pacstrap /mnt base linux-lts linux-lts-headers linux-firmware vim intel-ucode btrfs-progs

genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

#!/bin/bash

echo -ne "
------------------------------------------------------------------------
            Please select preset settings for your system              
------------------------------------------------------------------------
"
timedatectl set-ntp true
loadkeys us

touch $CONFIGS_DIR/1.txt
touch $CONFIGS_DIR/2.txt
touch $CONFIGS_DIR/3.txt
touch $CONFIGS_DIR/4.txt
touch $CONFIGS_DIR/5.txt
touch $CONFIGS_DIR/6.txt
touch $CONFIGS_DIR/7.txt
touch $CONFIGS_DIR/8.txt

echo -ne "
Please name your machine , this will be the host name:
"
read MACHINE_NAME
echo $MACHINE_NAME >> $CONFIGS_DIR/1.txt

echo -ne "
Please enter your username:
"
read USER_NAME
echo $USER_NAME >> $CONFIGS_DIR/2.txt

echo -ne "
Please enter your password:
"
read -s USER_PASSWORD # read password without echo
echo $USER_PASSWORD >> $CONFIGS_DIR/3.txt

echo -ne "
Please enter grub username for accessing grub: 
"
read GRUB_USERNAME
echo $GRUB_USERNAME >> $CONFIGS_DIR/4.txt

echo -ne "
Please provide a password for accessing grub:
"
read -s GRUB_PASSWORD
echo $GRUB_PASSWORD >> $CONFIGS_DIR/5.txt

echo -ne "
Please enter disk encryption password:
"
read -s LUKS_PASSWORD
echo $LUKS_PASSWORD >> $CONFIGS_DIR/6.txt

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
1    # Linux filesystem
t      # change partition type
2      # partition number
20     # Linux filesystem
w      # write partition table and exit
FDISK_CMDS

echo -ne "

-------------------------------------------------------------------------
                    creating filesystems
-------------------------------------------------------------------------

"

mkfs.fat -F32 ${disk}1
cryptsetup -y -v luksFormat ${disk}2
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << CRYPTSETUP_CMD | cryptsetup -v luksFormat ${disk}2
YES
cat $CONFIGS_DIR/6.txt
cat $CONFIGS_DIR/6.txt
CRYPTSETUP_CMD

sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << LUKSOPEN_CMD | cryptsetup luksOpen ${disk}2 cryptedsda2
cat $CONFIGS_DIR/6.txt
LUKSOPEN_CMD

mkfs.btrfs -f /dev/mapper/cryptedsda2

# store uuid of encrypted partition for grub
echo ENCRYPTED_PARTITION_UUID=$(blkid -s UUID -o value ${disk}2) >> $CONFIGS_DIR/7.txt

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

echo -ne "
------------------------------------------------------------------------
            Setting up pacman and arch core              
------------------------------------------------------------------------
"

pacman -S --noconfirm archlinux-keyring
pacstrap /mnt $(cat $PKGS_DIR/base-pacstrap)

echo -ne "
------------------------------------------------------------------------
            Setting up filesystem table             
------------------------------------------------------------------------
"
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

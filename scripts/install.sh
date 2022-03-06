#!/usr/bin/env bash

echo -ne "
------------------------------------------------------------------------
            Please select preset settings for your system              
------------------------------------------------------------------------
"



# selection for disk type

userinfo () {
read -p "Please enter your username: " username
set_option USERNAME ${username,,} # convert to lower case as in issue #109 
while true; do
  echo -ne "Please enter your password: \n"
  read -s password # read password without echo

  echo -ne "Please repeat your password: \n"
  read -s password2 # read password without echo

  if [ "$password" = "$password2" ]; then
    set_option PASSWORD $password
    break
  else
    echo -e "\nPasswords do not match. Please try again. \n"
  fi
done
read -rep "Please enter your hostname: " hostname
set_option NAME_OF_MACHINE $hostname
}




echo -ne "
-------------------------------------------------------------------------
                    formating disk
-------------------------------------------------------------------------

"

create_a_new_empty_GPT_partition_table='g q ' 
echo $create_a_new_empty_GPT_partition_table

add_a_new_partition1='n'
echo $add_a_new_partition1

change_a_partition_type='t'
echo $change_a_partition_type

list_known_partition_types='l'
echo $list_known_partition_types

add_a_new_partition2='n'
echo $add_a_new_partition2

write_table_to_disk_and_exit='w'
echo $write_table_to_disk_and_exit

echo "$create_a_new_empty_GPT_partition_table" 	| fdisk ${DISK}
echo "$add_a_new_partition1" 					| fdisk ${DISK}
echo "$change_a_partition_type" 				| fdisk ${DISK}
echo "$list_known_partition_types" 				| fdisk ${DISK}
echo "$add_a_new_partition2" 					| fdisk ${DISK}
echo "$write_table_to_disk_and_exit" 			| fdisk ${DISK}

# reread partition table to ensure it is correct
partprobe ${DISK}

# make filesystems
echo -ne "

-------------------------------------------------------------------------
                    creating filesystems
-------------------------------------------------------------------------

"
if [[ "${DISK}" =~ "nvme" ]]; then
    partition1=${DISK}p1
    partition2=${DISK}p2
else
    partition1=${DISK}1
    partition2=${DISK}2
fi


mkfs.fat -F32 ${partition1}
echo -n "${LUKS_PASSWORD}" | cryptsetup -y -v luksFormat ${partition2}
echo -n "${LUKS_PASSWORD}" | cryptsetup luksOpen ${partition2} cryptedPart-2
mkfs.btrfs /dev/mapper/cryptedPart-2

# store uuid of encrypted partition for grub
    echo ENCRYPTED_PARTITION_UUID=$(blkid -s UUID -o value ${partition2}) >> $CONFIGS_DIR/setup.conf

mount /dev/mapper/cryptedPart-2 /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@swap
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@snapshots

umount /mnt

mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@ /dev/mapper/cryptedPart-2 /mnt

mkdir /mnt/{home,swap,var,tmp,boot,snapshots}

mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@home /dev/mapper/cryptedPart-2 /mnt/home
mount -o noatime,compress=none,space_cache=v2,discard=async,subvol=@var /dev/mapper/cryptedPart-2 /mnt/var
mount -o noatime,compress=none,space_cache=v2,discard=async,subvol=@swap /dev/mapper/cryptedPart-2 /mnt/swap
mount -o noatime,compress=none,space_cache=v2,discard=async,subvol=@tmp /dev/mapper/cryptedPart-2 /mnt/tmp
mount -o noatime,compress=none,space_cache=v2,discard=async,subvol=@snapshots /dev/mapper/cryptedPart-2 /mnt/snapshots
mount ${partition1} /mnt/boot

pacstrap /mnt base linux linux-firmware vim intel-ucode btrfs-progs

genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "us" >> /etc/vconsole.conf
echo "$hostname" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts

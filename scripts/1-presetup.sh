#!/usr/bin/env bash

source $SCRIPT_DIR/configs/setup.conf

#SAVING SETUP PARAMETERS
if ! source $SCRIPT_DIR/configs/setup.conf; then
	# Loop through user input until the user gives a valid username
	while true
	do 
		read -p "Please enter your username: " username
		# username regex per response here https://unix.stackexchange.com/questions/157426/what-is-the-regex-to-validate-linux-users
		# lowercase the username to test regex
		if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]
		then 
			break
		fi 
		echo "Incorrect username."
	done 

    # Loop through user input until the user gives a valid hostname, but allow the user to force save 
	while true
	do 
		read -p "Please name your machine/host name: " name_of_machine
		# hostname regex (!!couldn't find spec for computer name!!)
		if [[ "${name_of_machine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]
		then 
			break 
		fi 
		# if validation fails allow the user to force saving of the hostname
		read -p "Hostname doesn't seem correct. Do you still want to save it? (y/n)" force 
		if [[ "${force,,}" = "y" ]]
		then 
			break 
		fi 
	done 

    echo "NAME_OF_MACHINE=${name_of_machine,,}" >> $SCRIPT_DIR/configs/setup.conf
    # convert name to lowercase before saving to setup.conf
    echo "USERNAME=${username,,}" >> $SCRIPT_DIR/configs/setup.conf
    #Set luks Password
    read -p "Please enter your luks password: " luks_password
    echo "LUKS_PASSWORD=${luks_password,,}" >> $SCRIPT_DIR/configs/setup.conf
    #Set root Password
    read -p "Please set root password: " root_password
    echo "ROOT_PASSWORD=${root_password,,}" >> $SCRIPT_DIR/configs/setup.conf
    # Set user Password
    read -p "Please enter your password: " password
    echo "PASSWORD=${password,,}" >> $SCRIPT_DIR/configs/setup.conf

fi


echo -ne "
------------------------------------------------------------------------
            PREPARING THE SYSTEM              
------------------------------------------------------------------------
"
loadkeys us
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true

echo -ne "
-------------------------------------------------------------------------
            FORMATING THE DISK
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

echo -ne "
------------------------------------------------------------------------
            INSTALLLING BARE METAL ARCH PACKAGES            
------------------------------------------------------------------------
"
pacman -S --noconfirm --needed archlinux-keyring
pacstrap /mnt $(cat $PKGS_DIR/base-pacstrap) --noconfirm --needed
mkdir /mnt/arch-linux
cp -R ${SCRIPT_DIR} /mnt/arch-linux
chmod +x /mnt/arch-install/arch-linux/scripts/2-setup.sh 
chmod +x /mnt/arch-install/arch-linux/scripts/3-postsetup.sh

echo -ne "
------------------------------------------------------------------------
SETTING UP FILE SYSTEM TABLES         
------------------------------------------------------------------------
"
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

loadkeys us
timedatectl set-ntp true
fdisk  /dev/sda
g
n +512M
t
1
n
w
mkfs.fat -F32 /dev/sda1
cryptsetup luksFormat /dev/sda2
cryptsetup luksOpen /dev/sda2 cryptedsda2
mkfs.btrfs /dev/mapper/ccryptedsda2
mount /dev/mapper/cryptedsda2 /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@swap
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@snapshots
umount /mnt
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@ /dev/mapper/ccryptedsda2 /mnt
mkdir /mnt/{home,swap,var,tmp,boot,snapshots}
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@home /dev/mapper/ccryptedsda2 /mnt/home
mount -o noatime,compress=zstd:1,space_cache=v2,discard=async,subvol=@home /dev/mapper/ccryptedsda2 /mnt/snapshots
mount -o noatime,compress=none,space_cache=v2,discard=async,subvol=@var /dev/mapper/ccryptedsda2 /mnt/var
mount -o noatime,compress=none,space_cache=v2,discard=async,subvol=@swap /dev/mapper/cryptedsda2 /mnt/swap
mount -o noatime,compress=none,space_cache=v2,discard=async,subvol=@tmp /dev/mapper/ccryptedsda2/mnt/tmp
mount /dev/sda1 /mnt/boot

pacstrap /mnt base linux linux-firmware vim intel-ucode btrfs-progs
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

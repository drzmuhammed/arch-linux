#!/bin/bash
echo -ne "
-------------------------------------------------------------------------
            AUTOMATED ARCH LINUX INSTALLER
-------------------------------------------------------------------------
            LUKS-BTRFS-GRUB-GRUBPASSWORD-SYSTEMD-APPARMOR-SNAPPER
-------------------------------------------------------------------------
"

# Find the name of the folder the scripts are in
set -a
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPTS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/scripts
CONFIGS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/configs
PKGS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/pkgs
set +a

( bash $SCRIPTS_DIR/0-startup.sh.sh )|& tee 0-startup.log
( bash $SCRIPTS_DIR/1-presetup.sh )|& tee 1-presetup.log
source $CONFIGS_DIR/setup.conf
( arch-chroot /mnt $HOME/arch-linux/scripts/2-setup.sh )|& tee 2-setup.log
cp -v *.log /mnt/root/arch-linux

echo -ne "
-------------------------------------------------------------------------
            AUTOMATED ARCH LINUX INSTALLER
-------------------------------------------------------------------------
            ARCH INSTALLATION COMPLETE AND READY TO USE
-------------------------------------------------------------------------
"
echo -ne "
unmounting all file system
"
umount -a
echo -ne "
rebooting now
"
reboot

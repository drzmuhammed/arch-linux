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

( bash $SCRIPTS_DIR/0-startup.sh )|& tee 0-startup.log
source $CONFIGS_DIR/setup.conf
( bash $SCRIPTS_DIR/1-presetup.sh )|& tee 1-presetup.log
( arch-chroot /mnt arch-linux/scripts/2-setup.sh )|& tee 2-setup.log
# ( arch-chroot /mnt $HOME/arch-linux/scripts/3-postsetup.sh )|& tee 3-postsetup.log
cp -v *.log /mnt/arch-install

echo -ne "
-------------------------------------------------------------------------
            PLEASE EJECT INSTALL MEDIA AND REBOOT
-------------------------------------------------------------------------
"

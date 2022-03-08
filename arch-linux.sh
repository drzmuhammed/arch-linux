#!/bin/bash
echo -ne "

-------------------------------------------------------------------------
                    automated arch linux installer
-------------------------------------------------------------------------
             arch-linux-luks-btrfs-grubEncrypt-apparmor-snapper
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
umount -a

cp -v *.log /mnt/root/arch-linux

echo -ne "
-------------------------------------------------------------------------
                    automated arch linux installer
-------------------------------------------------------------------------
                        system setup complete
-------------------------------------------------------------------------
                        system is ready to use
-------------------------------------------------------------------------

"

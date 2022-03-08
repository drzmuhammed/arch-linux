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

touch $CONFIGS_DIR/setup.conf
( bash $SCRIPTS_DIR/presetup.sh )|& tee presetup.log
source $CONFIGS_DIR/setup.conf
( arch-chroot /mnt $HOME/arch-linux/scripts/setup.sh )|& tee setup.log

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

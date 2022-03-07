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
arch-chroot /mnt 
( bash $SCRIPTS_DIR/setup.sh )|& tee setup.log

cp -v *.log /mnt/home/$user_name

echo -ne "
-------------------------------------------------------------------------
                    automated arch linux installer
-------------------------------------------------------------------------
                        system setup complete
-------------------------------------------------------------------------
                        system is ready to use
-------------------------------------------------------------------------

"

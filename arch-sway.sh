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
set +a

touch $CONFIGS_DIR/setup.conf
( bash $SCRIPT_DIR/scripts/install.sh )|& tee install.log
cp -v *.log /mnt/home/$USERNAME

echo -ne "
-------------------------------------------------------------------------
                    automated arch linux installer
-------------------------------------------------------------------------
                        system setup complete
-------------------------------------------------------------------------

"

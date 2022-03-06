#!/usr/bin/env bash
echo -ne "
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
                        SCRIPTHOME: arch-sway
-------------------------------------------------------------------------

Final Setup and Configurations
GRUB EFI Bootloader Install & Check
"
source ${HOME}/arch-sway/configs/setup.conf

if [[ -d "/sys/firmware/efi" ]]; then
    grub-install --efi-directory=/boot ${DISK}
fi

echo -ne "
-------------------------------------------------------------------------
                Grub Boot Menu Setup
-------------------------------------------------------------------------
"
# set kernel parameter for decrypting the drive
sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "All set!"

echo -ne "

-------------------------------------------------------------------------
                    Enabling Essential Services
-------------------------------------------------------------------------

"
systemctl enable acpid.service
echo "  enabling acpid.service"
systemctl enable apparmor.service
echo "  enabling  apparmor.service"
systemctl enable auditd.service
echo "  enabling  auditd.service"
systemctl enable bluetooth.service
echo "  enabling  bluetooth.service"
systemctl enable cpupower.service
echo "  enabling  cpupower.service"
systemctl enable fail2ban.service
echo "  enabling  fail2ban.service"
systemctl enable fstrim.timer
echo "  enabling  fstrim.timer"
systemctl enable NetworkManager.service
echo "  enabling  NetworkManager.service"
systemctl enable reflector.timer
echo "  enabling reflector.timer"
systemctl enable systemd-remount-fs.service
echo "  enabling systemd-remount-fs.service"
systemctl enable systemd-resolved.service
echo "  enabling  systemd-resolved.service"
systemctl enable systemd-timesyncd.service
echo "  enabling  systemd-timesyncd.service"
systemctl enable thermald.service
echo "  enabling  thermald.service"
systemctl enable tlp.service
echo "  enabling  tlp.service"
systemctl enable ufw.service
echo "  enabling  ufw.service"

echo -ne "

-------------------------------------------------------------------------
                    Cleaning
-------------------------------------------------------------------------

"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

rm -r $HOME/arch-sway
rm -r /home/$USERNAME/arch-sway

# Replace in the same state
cd $pwd

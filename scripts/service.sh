#!/bin/bash

-------------------------------------------------------------------------
                    Enabling Essential Services
-------------------------------------------------------------------------

"
systemctl enable acpid.service
echo -ne "  enabling acpid.service"
systemctl enable apparmor.service
echo -ne "  enabling  apparmor.service"
systemctl enable auditd.service
echo -ne "  enabling  auditd.service"
systemctl enable bluetooth.service
echo -ne "  enabling  bluetooth.service"
systemctl enable cpupower.service
echo -ne "  enabling  cpupower.service"
systemctl enable fail2ban.service
echo -ne "  enabling  fail2ban.service"
systemctl enable fstrim.timer
echo -ne "  enabling  fstrim.timer"
systemctl enable NetworkManager.service
echo -ne "  enabling  NetworkManager.service"
systemctl enable reflector.timer
echo -ne "  enabling reflector.timer"
systemctl enable systemd-remount-fs.service
echo -ne "  enabling systemd-remount-fs.service"
systemctl enable systemd-resolved.service
echo -ne "  enabling  systemd-resolved.service"
systemctl enable systemd-timesyncd.service
echo -ne "  enabling  systemd-timesyncd.service"
systemctl enable thermald.service
echo -ne "  enabling  thermald.service"
systemctl enable tlp.service
echo -ne "  enabling  tlp.service"
systemctl enable ufw.service
echo -ne "  enabling  ufw.service"

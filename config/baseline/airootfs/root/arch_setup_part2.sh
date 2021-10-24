#!/bin/bash

# Arch Linux Installation
# -----------------------
# Part 2 - inside the arch chroot environment


ln -s /usr/share/zoneinfo/Europe/London /etc/localtime

hwclock --systohc


#vim /etc/locale.gen
# uncomment en_GB.UTF-8 UTF-8
sed -i 's|#en_GB.UTF-8|en_GB.UTF-8|' /etc/locale.gen

locale-gen

echo LANG=en_GB.UTF-8 >> /etc/locale.conf

echo KEYMAP=uk >> /etc/vconsole.conf

echo -n "Enter hostname: "
read HOST_NAME
echo "$HOST_NAME" >> /etc/hostname

# add 3 lines from arch linux install wiki
cat <<EOT >> /etc/hosts
127.0.0.1	localhost
::1		localhost
127.0.1.1	${HOST_NAME}.localdomain myhostname
EOT

echo "Enter Root password"
passwd

echo "Enter user (judge) password"
useradd -m judge
passwd judge

usermod -aG wheel,audio,video,storage,optical judge

# configure sudo for user
cat > /etc/sudoers.d/judge <<-EOF
judge ALL=(ALL) NOPASSWD: ALL
EOF

pacman -S grub efibootmgr dosfstools os-prober mtools openssh

if fdisk -l | grep -q "EFI System"
then

# UEFI
mkdir /boot/EFI
mount /dev/vda1 /boot/EFI
grub-install --target=x86_64-efi --bootloader-id=grub-efi --recheck

else

# BIOS
grub-install --target=i386-pc /dev/vda

fi

grub-mkconfig -o /boot/grub/grub.cfg

# some sstem setup
systemctl enable NetworkManager
systemctl enable sshd
sed -i 's|#ParallelDownloads.*|ParallelDownloads = 5|' /etc/pacman.conf
sed -i 's|\(ParallelDownload.*\)|\1\nILoveCandy|' /etc/pacman.conf


echo -e "\nFinished. Reboot now. [Enter] "
read

reboot


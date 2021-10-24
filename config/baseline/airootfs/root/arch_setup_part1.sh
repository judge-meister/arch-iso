#!/bin/bash

# Arch Linux Installation
# -----------------------
# Part 1 - setup disk partitions and start arch-chroot

echo "Setting UK keyboard ..."
loadkeys uk

echo "Setting Timezone/NTP ..."
timedatectl set-ntp true
timedatectl set-timezone Europe/London
timedatectl status


echo ""
# -- question - BIOS or UEFI
while [ "$BOOT" != "b" ] && [ "$BOOT" != 'u' ]
do
  echo -n "boot via BIOS or UEFI [b/u]: "
  read BOOT
done

# swapsize is 2*RAM or 8GB which ever is smaller
MEMSIZE=$(lsmem -o SIZE -P | awk -F'"' '{print $2}' | sed 's|G||g')
SWAPSIZE=$((MEMSIZE*2))
if [ "$SWAPSIZE" -gt 8 ]
then
  SWAPSIZE=8
fi

if [ "$BOOT" == "b" ]
then

### USING BIOS ###

# get hard disk
if [ "$(ls /dev/[sxv]d? | wc -l)" -eq 1 ]
then
  DISK=$(ls /dev/[sxv]d?)
  echo "Found $DISK"
else
  lsblk
  # -- question - ask which disk
  while [ ! -b "$DISK" ]
  do
    echo "Enter disk device name: [/dev/vda] "
    read DISK
  done
fi

DISK_SIZE=$(lsblk $DISK | grep "^${DISK}" | awk -F' ' '{print $4}' | sed 's|G||')

# for a BIOS based install
# create DOS partition table (grub-install requires DOS)
# o,
# n, p, 1, (def), +28G,
# n, p, 2, (def), (def), t, 2, 82
# w

echo "Partitioning Disk ..."

fdisk "$DISK" <<-EOF
o
n
p
1

+$((DISK_SIZE-SWAPSIZE))G
n
p
2


t
2
82
p
w
EOF


# make filesystems

echo -e "\nMaking Swap..."
mkswap /dev/vda2
echo -e "\nMaking Ext4 partition ..."
mkfs.ext4 /dev/vda1

# mount disks

echo -e "\nMounting Disks ..."
mount /dev/vda1 /mnt
swapon /dev/vda2


# -------------------------------------
else

### USING UEFI ###

# for a EFI based install
# create 3 partitions (assuming 30G disk)
#vda1 550MB @ start of disk, type EFI, formatted MSDOS 
#vda2 8GB @ end of disk, type Linux swap
#vda3 28GB the rest of the disk, type Linux, formatted ext4
#fdisk -l

echo "Partitioning Disk ..."
# gpt partition
fdisk /dev/vda <<-EOF
g
n
1

+550M
t
1
uefi
n
2

+${SWAPSIZE}G
t
2
swap
n
3


p
w
EOF

# make filesystems

echo -e "\nMaking Swap ..."
mkswap /dev/vda2
echo -e "\nMaking Ext4 partition ..."
mkfs.ext4 /dev/vda3
echo -e "\nMaking FAT32 partition ..."
mkfs.fat -F32 /dev/vda1

# mount disks
echo -e "\nMounting Disks ..."
mount /dev/vda3 /mnt
swapon /dev/vda2

fi

echo -ne "\nUncomment a UK server or 2 ? "
read 
nano /etc/pacman.d/mirrorlist

# install base system
pacman-key --init
pacman-key --refresh-keys
pacman-key --populate archlinux

echo -e "\nInstalling Boot Strap system ..."
pacstrap /mnt base base-devel linux linux-firmware vim sudo grub git networkmanager

# setup chroot

genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

mkdir -p /mnt/root
cp arch_setup_part2.sh /mnt/root/

echo -e "\nNext run /root/arch_setup_part2.sh from inside the chroot"

echo -e "\nStarting chroot ... ?"
read

arch-chroot /mnt



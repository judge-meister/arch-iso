#!/bin/bash

# build my own arch linux install iso

TMPDIR=/tmp/$$.archiso.tmp
ISODIR=/tmp/$$.archiso

if ! pacman -Q | grep "^archiso"
then
  echo "This needs archiso installed. Try 'pacman -Sy archiso'"
  exit
fi

sudo rm -rf $TMPDIR
mkdir -p $TMPDIR $ISODIR

sudo mkarchiso -w $TMPDIR -o $ISODIR ./config/baseline/

if [ -d /home/judge/Virt-Manager/ISOs ]
then
  sudo cp $ISODIR/archlinux-*-x86_64.iso /home/judge/Virt-Manager/ISOs/
fi

mv $ISODIR/*.iso ~/
sudo rm -rf $TMPDIR $ISODIR


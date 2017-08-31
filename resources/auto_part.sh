#!/bin/bash
#
#  This file is part of Nemesis.
#
#  Nemesis is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Nemesis is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  The following additional terms are in effect as per Section 7 of the license:
#
#  The preservation of all legal notices and author attributions in
#  the material or in the Appropriate Legal Notices displayed
#  by works containing it is required.
#
#  You should have received a copy of the GNU General Public License
#  along with Nemesis; If not, see <http://www.gnu.org/licenses/>.


cd /home/liveuser/nemesis/resources
source nemesis.conf

Parted() {
	parted --script $dev "$1"
}

# Find total amount of RAM
	if [[ -d "/sys/firmware/efi/" ]]; then
      SYSTEM="UEFI"
      else
      SYSTEM="BIOS"
	fi



	ram=$(grep MemTotal /proc/meminfo | awk '{print $2/1024}' | sed 's/\..*//')
	# Find where swap partition stops
	num=4000

	if [ "$ram" -gt "$num" ]
		then swap_space=4096
		else swap_space=$ram
	fi
	
	uefi_swap=$(($swap_space + 513))


	#BIOS or UEFI
    if [ "$SYSTEM" = "BIOS" ]
        then
	        dd if=/dev/zero of=$dev bs=512 count=1
	        Parted "mklabel msdos"
	        Parted "mkpart primary ext4 1MiB 100%"
	        Parted "set 1 boot on"
	        mkfs.ext4 -F ${dev}1
	        mount ${dev}1 /mnt
		touch /mnt/swapfile
		dd if=/dev/zero of=/mnt/swapfile bs=1M count=${swap_space}
		chmod 600 /mnt/swapfile
		mkswap /mnt/swapfile
		swapon /mnt/swapfile
		swapfile="yes"
	    else
            	dd if=/dev/zero of=$dev bs=512 count=1
            	Parted "mklabel gpt"
            	Parted "mkpart primary fat32 1MiB 513MiB"
		Parted "mkpart primary ext4 513MiB 100%"
		Parted "set 1 boot on"
		mkfs.fat -F32 ${dev}1
		mkfs.ext4 -F ${dev}2
		mount ${dev}2 /mnt
		mkdir -p /mnt/boot
		mount ${dev}1 /mnt/boot
		touch /mnt/swapfile
		dd if=/dev/zero of=/mnt/swapfile bs=1M count=${swap_space}
		chmod 600 /mnt/swapfile
		mkswap /mnt/swapfile
		swapon /mnt/swapfile
		swapfile="yes"
	fi
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

arch_chroot() {
    arch-chroot /mnt /bin/bash -c "${1}"
}

if [[ -d "/sys/firmware/efi/" ]]; then
      SYSTEM="UEFI"
      else
      SYSTEM="BIOS"
fi

grub_device=$dev


# running mkinit

arch_chroot "mkinitcpio -p linux"

lts=` cat /home/liveuser/nemesis/pkg_list/packages.txt `

if [ $(echo lts | grep linux-lts) != "" ]
    then arch_chroot "mkinitcpio -p linux-lts"
fi

# installing bootloader
if [ "$grub" = "Yes" ]
    then
        if [ "$SYSTEM" = 'BIOS' ]
            then echo "98"
	    echo "# Installing Bootloader..."
            pacstrap /mnt grub os-prober
	    # fixing grub theme
	    echo "GRUB_DISTRIBUTOR='Revenge OS'" >> /mnt/etc/default/grub
	    if [ "$type" = "StationX" ]
		then echo 'GRUB_BACKGROUND="/usr/share/Wallpaper/Shadow_cast-StationX.png"' >> /mnt/etc/default/grub
		else
	    	     echo 'GRUB_BACKGROUND="/usr/share/Wallpaper/Shadow_cast-RevengeOS.png"' >> /mnt/etc/default/grub
	    fi
            arch_chroot "grub-install --target=i386-pc --recheck --force --debug $grub_device"
            arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
        else
            echo "98"
	    echo "# Installing Bootloader..."


            if [ "$ans" = "Automatic Partitioning" ]
                then root_part=${grub_device}2
            fi

            pacstrap /mnt grub efibootmgr
            # fixing grub theme
            echo "GRUB_DISTRIBUTOR='Revenge OS'" >> /mnt/etc/default/grub
            if [ "$type" = "StationX" ]
		then echo 'GRUB_BACKGROUND="/usr/share/Wallpaper/Shadow_cast-StationX.png"' >> /mnt/etc/default/grub
		else
	    	     echo 'GRUB_BACKGROUND="/usr/share/Wallpaper/Shadow_cast-RevengeOS.png"' >> /mnt/etc/default/grub
	    fi
            arch_chroot "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub"
            arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
            # additional fix for virtualbox efi boot
            mkdir -p /mnt/boot/EFI/BOOT
            cp /mnt/boot/EFI/grub/grubx64.efi /mnt/boot/EFI/BOOT/BOOTX64.EFI
        fi
fi  


if [ "$type" = "StationX" ]
    then # setting stationx wallpapers
        if [ "$desktop" = "KDE Plasma" ]
		then sed -i 's/Mt_Shadow_Red_Dawn-RevengeOS.png/Mt_Shadow_Red_Dawn-StationX.png/g' /mnt/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc
		sed -i 's/Mt_Shadow_Red_Dawn-RevengeOS.png/Mt_Shadow_Red_Dawn-StationX.png/g' /mnt/root/.config/plasma-org.kde.plasma.desktop-appletsrc
	else
		sed -i 's/Mt_Shadow_Red_Dawn-RevengeOS.png/Mt_Shadow_Red_Dawn-StationX.png/g' /mnt/etc/skel/.config/nitrogen/bg-saved.cfg
		sed -i 's/Mt_Shadow_Red_Dawn-RevengeOS.png/Mt_Shadow_Red_Dawn-StationX.png/g' /mnt/root/.config/nitrogen/bg-saved.cfg
		echo "theme-name = BlackMATE" >> /mnt/etc/lightdm/lightdm-gtk-greeter.conf
        	echo "background = /usr/share/Wallpaper/Behind_the_scenes-StationX-v2.png" >> /mnt/etc/lightdm/lightdm-gtk-greeter.conf
                echo "position = 23%,center 46%,center" >> /mnt/etc/lightdm/lightdm-gtk-greeter.conf
	fi
        
fi


# unmounting partitions
umount -R /mnt
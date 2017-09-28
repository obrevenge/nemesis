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


# Setting up plymouth theme to work
sed -i 's/base udev/base udev plymouth/g' /mnt/etc/mkinitcpio.conf

# Installing plymouth theme
pacstrap /mnt revenge-plymouth-theme


# fix theme for applications running as root
cp -r /mnt/etc/skel/. /mnt/root/

#root password
touch .passwd
echo -e "$rtpasswd1\n$rtpasswd2" > .passwd
arch_chroot "passwd root" < .passwd >/dev/null

# autostart for normal or oem
if [ "$type" = "OEM" ]
    then # setting oem script for autostart
        cp -r oem-install /mnt/etc/
        cp oem-setup.sh /mnt/usr/bin/
fi

if [ "$type" = "StationX" ]
    then # setting oem script for autostart
        cp -r oem-install /mnt/etc/
        cp oem-setup.sh /mnt/usr/bin/
        
fi

# setting welcome screen to auto-start
mkdir -p /mnt/etc/skel/.config/autostart
cp obwelcome.desktop /mnt/etc/skel/.config/autostart/

# adding user depending on type of install
if [ "$type" = "Normal" ]
    then
    arch_chroot "useradd -m -g users -G adm,lp,wheel,power,audio,video -s /bin/bash $username"
    arch_chroot "passwd $username" < .passwd >/dev/null
    rm .passwd
    # making sure config files are sent to user's home directory
    arch_chroot "cp -r /etc/skel/. /home/${username}/"
else
    mkdir -p /etc/systemd/system
    cp -r /mnt/etc/oem-install/getty@tty1.service.d /mnt/etc/systemd/system/
    cp -f /mnt/etc/oem-install/.bash_profile /mnt/root/
    cp -f /mnt/etc/oem-install/.xinitrc /mnt/root/
    cp -f /mnt/etc/oem-install/.xsession /mnt/root/
    cp -f /mnt/etc/oem-install/.Xresources /mnt/root/
    mkdir -p /mnt/root/.config/autostart
    cp oem.desktop /mnt/root/.config/autostart/
    mkdir -p /mnt/root/.config/i3
    cp -f /mnt/etc/oem-install/config /mnt/root/.config/i3/

    if [ "$desktop" = "Gnome" ]
    	then sed -i 's/openbox-session/gnome-session/g' /mnt/root/.xinitrc
    elif [ "$desktop" = "KDE PLasma" ]
        then sed -i 's/openbox-session/startkde/g' /mnt/root/.xinitrc
    elif [ "$desktop" = "XFCE" ]
        then sed -i 's/openbox-session/startxfce4/g' /mnt/root/.xinitrc
    elif [ "$desktop" = "Mate" ]
        then sed -i 's/openbox-session/mate-session/g' /mnt/root/.xinitrc
    elif [ "$desktop" = "i3" ]
        then sed -i 's/openbox-session/i3/g' /mnt/root/.xinitrc
    fi

fi    


# enabling network manager
arch_chroot "systemctl enable NetworkManager"


# fixing revenge branding
rm -f /mnt/etc/os-release
cp os-release /mnt/etc/os-release


# starting desktop manager
if [ "$type" = "Normal" ];then

    if [ "$desktop" = "Gnome" ]
        then arch_chroot "systemctl enable gdm-plymouth.service"
    else
        pacstrap /mnt lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
        arch_chroot "systemctl enable lightdm-plymouth.service"
        echo "theme-name = BlackMATE" >> /mnt/etc/lightdm/lightdm-gtk-greeter.conf
        echo "background = /usr/share/Wallpaper/Shadow_cast-RevengeOS-v2.png" >> /mnt/etc/lightdm/lightdm-gtk-greeter.conf
    fi
fi

if [ "$type" = "StationX" ]
    then # installing stationx wallpapers
	pacstrap /mnt revenge-stationx-wallpapers
fi 

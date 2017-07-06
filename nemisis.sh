#!/bin/bash

rm nemesis.conf
rm mountpoints
rm mounts
rm config1.txt
rm config2.txt
rm .passwd

title="Nemesis Installer"

greeting() {
    yad --width=600 --height=400 --center --title="$title" --image="crosshairs.png" --image-on-top --form --field=" ":LBL --image-on-top --field="<big>Welcome to the Nemesis Installer</big>\n\nThank you for Choosing a Revenge OS System. Click Okay to Get Started":LBL > answer.txt

    answer=` cat answer.txt `

    if [ "$answer" = "" ]
        then exit
    fi
}
                                                   
partitions() {
    yad --width=600 --height=400 --center --title="$title" --text="Partitions" --text="<big>Partitioning</big>\n\nHow Would You Like to Partition Your Disk? Auto Partitioning will delete everything on the disk and install Revenge OS\n\nManual Partitioning will allow you to create and edit partitions and choose where to install Revenge OS" --image="$logo" --radiolist --list --column="Select" --column="Type" false "Automatic Partioning" false "Manual Partitioning" --separator=" " > answer.txt   

    part=` cat answer.txt | awk '{print $2;}' `

    if [ "$part" == "Manual" ]
        then echo "partition=\"manual\"" >> nemesis.conf
        gparted
        partitions=` find /dev -mindepth 1 -maxdepth 1  -name "*[sh]d[a-z][0-9]"  | sort | xargs -0 `
        fields=$(for i in $(echo $partitions)
            do
                echo "--field=${i}:CB"
            done)
            mounts=$(yad --width=600 --height=500 --title="$title" --text="What Partitions Do You Want to Use?\nSelect a Mount Point for Each Partition that You want to Use." --image="$logo" --separator=" " --form $fields \
            "NA!/boot!/!/home!/var!/data!/media!swap" "NA!/boot!/!/home!/var!/data!/media!swap" "NA!/boot!/!/home!/var!/data!/media!swap" "NA!/boot!/!/home!/var!/data!/media!swap" "NA!/boot!/!/home!/var!/data!/media!swap" "NA!/boot!/!/home!/var!/data!/media!swap" "NA!/boot!/!/home!/var!/data!/media!swap" "NA!/boot!/!/home!/var!/data!/media!swap" "NA!/boot!/!/home!/var!/data!/media!swap" "NA!/boot!/!/home!/var!/data!/media!swap")
        
            rm mounts.txt
            for m in $(echo $mounts)
                do
                    num="1"
                    echo "/mnt$m" >> mounts.txt
                    num="$num + 1"
                done
        
            rm mountpoints.txt
            for i in $(echo $partitions)
                do
                    line=$(head -n 1 mounts.txt)
                    echo "mount $i $line" >> mountpoints
                    tail -n +2 mounts.txt > mounts.txt.tmp && mv mounts.txt.tmp mounts.txt
                done
        
            chmod +x mountpoints
        elif [ "$part" == "Automatic" ]
            then echo "partition=\"automatic\"" >> nemesis.conf
            auto_partition
        

    fi
}

config1(){
    locales=$(cat /etc/locale.gen | grep -v "#  " | sed 's/#//g' | sed 's/ UTF-8//g' | grep .UTF-8 | sort | awk '{ printf "!""\0"$0"\0" }')

    zones=$(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sed "s/\/.*//g" | sort -ud | sort | awk '{ printf "!""\0"$0"\0" }')

    yad --width=600 --height=400 --center --title="$title" --image="$logo" --text "Configuration" --form --field="Select Your Keyboard Layout:":CB --field="Select Your locale:":CB --field="Select Your Region:":CB --separator=" " \
    "us!af!al!am!at!az!ba!bd!be!bg!br!bt!bw!by!ca!cd!ch!cm!cn!cz!de!dk!ee!es!et!eu!fi!fo!fr!gb!ge!gh!gn!gr!hr!hu!ie!il!in!iq!ir!is!it!jp!ke!kg!kh!kr!kz!la!lk!lt!lv!ma!md!me!mk!ml!mm!mn!mt!mv!ng!nl!no!np!pc!ph!pk!pl!pt!ro!rs!ru!se!si!sk!sn!sy!tg!th!tj!tm!tr!tw!tz!ua!uz!vn!za" "en_US-UTF-8 $locales" "$zones" > config1.txt

    key=` cat config1.txt | awk '{print $1;}' `
    locale=` cat config1.txt | awk '{print $2;}' `
    zone=` cat config1.txt | awk '{print $3;}' `

    echo "key=\"$key\"" >> nemesis.conf
    echo "locale=\"$locale\"" >> nemesis.conf
    echo "zone=\"$zone\"" >> nemesis.conf

    rm config1.txt
}

config2() {
    subzones=$(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "$zone/" | sed "s/$zone\///g" | sort -ud | sort | awk '{ printf "!""\0"$0"\0" }')

    yad --width=600 --height=400 --center --title="$title" --image="$logo" --text "Configuration" --form --field="Select your sub-zone:":CB --field="Use UTC or Local Time?":CB --field="Choose a hostname:" --field="Choose a username:" --field="Enter Your User Password:H" --field="Re-enter Your User Password:H" --separator=" " \
    "$subzones" "!UTC!Localtime" "" "" "" "" > config2.txt

    subzone=` cat config2.txt | awk '{print $1;}' `
    clock=` cat config2.txt | awk '{print $2;}' `
    hname=` cat config2.txt | awk '{print $3;}' `
    username=` cat config2.txt | awk '{print $4;}' `
    rtpasswd1=` cat config2.txt | awk '{print $5;}' `
    rtpasswd2=` cat config2.txt | awk '{print $6;}' `

    if [ "$rtpasswd1" != "$rtpasswd2" ]
            then zenity --error --title="$title" --text "The passwords did not match, please try again." --height=40
            config2
    fi

    echo "subzone=\"$subzone\"" >> nemesis.conf
    echo "clock=\"$clock\"" >> nemesis.conf
    echo "hname=\"$hname\"" >> nemesis.conf
    echo "username=\"$username\"" >> nemesis.conf
    echo -e "$rtpasswd1\n$rtpasswd2" > .passwd
}

vbox() {
graphics=$(lspci | grep -i "vga" | sed 's/.*://' | sed 's/(.*//' | sed 's/^[ \t]*//')
if [[ $(echo $graphics | grep -i 'virtualbox') != "" ]]
	then vbox="yes"
fi
}

desktop() {
    desktops=$(yad --width=600 --height=400 --center --title="$title" --text="Desktops" --text="<big>Desktops</big>\n\nWhich Revenge OS Desktop would you like to install?" --image="$logo" --radiolist --list --column="Select" --column="Desktop" false "OBR Openbox" false "Gnome" false "Plasma" false "XFCE" false "Mate" false "i3" --separator=" ")
    echo $desktops
    
    desktop=` echo $desktops | awk '{print $2;}' `
    
    echo "desktop=\"$desktop\"" >> nemesis.conf
    
}

# bootloader?
bootloader() {
lsblk -lno NAME,TYPE | grep 'disk' | awk '{print "/dev/" $1 " " $2}' | sort -u > devices.txt
sed -i 's/\<disk\>//g' devices.txt
devices=` awk '{print "FALSE " $0}' devices.txt `

grub=$(zenity --question --title="$title" --text "Would you like to install the bootloader?\nThe answer to this is usually yes,\nunless you are dual-booting and plan to have another system handle\nthe boot process.")
if [ "$grub" = "$1" ]
	then grub_device=$(zenity --list --title="$title" --text "Where do you want to install the bootloader?" --radiolist --column Select --column Device $devices)
fi
}

confirm() {
    ans=$(yad --width=600 --center --radiolist --list --title="$title" --image="$logo" --text="You have chosen the following:\n\n$part partitioning\n\nKeyboard layout: $key\n\nTimezone: $zone $subzone\n\nHostname: $hname\n\nUsername: $username\n\nClock configuration: $clock\n\nDesktop: $desktop\n\nIf the above options are correct, click Continue.\nIf you need to make changes, click 'Cancel' to start over." --column="Select" --column="Choice" false "Continue" false "Cancel" --separator=" ")
    
    answer=` echo $ans | awk '{print $2;}' `
    
    if [ "$answer" = "Cancel" ]
        then greeting
    fi
    
}

auto_partition() {
	list=` lsblk -lno NAME,TYPE,SIZE,MOUNTPOINT | grep "disk" `

	zenity --info --title="$title" --text "Below is a list of the available drives on your system:\n\n$list" --height=10 width=150

	lsblk -lno NAME,TYPE | grep 'disk' | awk '{print "/dev/" $1 " " $2}' | sort -u > devices.txt
	sed -i 's/\<disk\>//g' devices.txt
	devices=` awk '{print "FALSE " $0}' devices.txt `

	dev=$(zenity --list --title="$title" --radiolist --text "Select the drive that you want to use for installation." --column Drive --column Info $devices)

        touch root_part.txt
        if [ "$SYSTEM" = "BIOS" ]
	then echo {$dev}1 >> root_part.txt
	else echo {$dev}2 >> root_part.txt
        fi 

	# Find total amount of RAM
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
	       (echo "# Creating Partitions for BIOS..."
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
		swapfile="yes") | zenity --progress --title="$title" --width=450 --pulsate --auto-close --no-cancel
	    else
            	(echo "# Creating Partitions for UEFI..."
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
		swapfile="yes") | zenity --progress --title="$title" --width=450 --pulsate --auto-close --no-cancel
	fi
			
}

installing() {
(
# sorting pacman mirrors
echo "# Sorting fastest pacman mirrors..."
reflector --verbose -l 50 -p http --sort rate --save /etc/pacman.d/mirrorlist

# updating pacman cache
echo "# Updating Pacman Cache..."
pacman -Syy
arch_chroot "pacman -Syy"

#installing base
echo "# Installing Base..."
pacstrap /mnt base base-devel

#fixing pacman.conf
rm -f /mnt/etc/pacman.conf
cp /etc/pacman.conf /mnt/etc/pacman.conf


#generating fstab
echo "# Generating File System Table..."
genfstab -p /mnt >> /mnt/etc/fstab
if grep -q "/mnt/swapfile" "/mnt/etc/fstab"; then
sed -i '/swapfile/d' /mnt/etc/fstab
echo "/swapfile		none	swap	defaults	0	0" >> /mnt/etc/fstab
fi

#root password
echo "# Setting root password..."
touch .passwd
echo -e "$rtpasswd1\n$rtpasswd2" > .passwd
arch_chroot "passwd root" < .passwd >/dev/null

#adding user
echo "# Making new user..."
arch_chroot "useradd -m -g users -G adm,lp,wheel,power,audio,video -s /bin/bash $username"
arch_chroot "passwd $username" < .passwd >/dev/null
rm .passwd

#setting locale
echo "# Generating Locale..."
echo "LANG=\"${locale}\"" > /mnt/etc/locale.conf
echo "${locale} UTF-8" > /mnt/etc/locale.gen
arch_chroot "locale-gen"
export LANG=${locale}

#setting keymap
mkdir -p /mnt/etc/X11/xorg.conf.d/
echo -e 'Section "InputClass"\n	Identifier "system-keyboard"\n	MatchIsKeyboard "on"\n	Option "XkbLayout" "'$key'"\n	Option "XkbModel" "'$model'"\n	Option "XkbVariant" ",'$variant'"\n	 Option "XkbOptions" "grp:alt_shift_toggle"\nEndSection' > /mnt/etc/X11/xorg.conf.d/00-keyboard.conf

#setting timezone
echo "# Setting Timezone..."
arch_chroot "rm /etc/localtime"
arch_chroot "ln -s /usr/share/zoneinfo/${zone}/${subzone} /etc/localtime"

#setting hw clock
echo "# Setting System Clock..."
arch_chroot "hwclock --systohc --$clock"

#setting hostname
echo "# Setting Hostname..."
arch_chroot "echo $hname > /etc/hostname"

# setting sudo permissions
echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers

# installing video and audio packages
echo "# Installing Desktop, Sound, and Video Drivers..."
pacstrap /mnt  mesa xorg-server xorg-apps xorg-xinit xorg-drivers xterm alsa-utils pulseaudio pulseaudio-alsa xf86-input-synaptics xf86-input-keyboard xf86-input-mouse xf86-input-libinput intel-ucode b43-fwcutter networkmanager nm-connection-editor network-manager-applet polkit-gnome gksu ttf-dejavu gnome-keyring xdg-user-dirs gvfs libmtp gvfs-mtp wpa_supplicant dialog iw reflector rsync mlocate bash-completion htop unrar p7zip yad yaourt pamac-aur polkit-gnome lynx wget zenity gksu squashfs-tools ntfs-3g gptfdisk cups ghostscript gsfonts

# virtualbox
if [ "$vbox" = "yes" ]
	then pacstrap /mnt virtualbox-guest-modules-arch virtualbox-guest-utils
    echo -e "vboxguest\nvboxsf\nvboxvideo" > /mnt/etc/modules-load.d/virtualbox.conf
fi

# installing chosen desktop
if [ "$desktop" = "Gnome" ]
    then pacstrap /mnt gnome gnome-extra gnome-revenge-desktop
elif [ "$desktop" = "OBR Openbox" ]
    then pacstrap /mnt obr-desktop
elif [ "$desktop" = "Plasma" ]
    then pacstrap /mnt plasma plasma-revenge-desktop
elif [ "$desktop" = "XFCE" ]
    then pacstrap /mnt xfce4 xfce4-goodies xfce-revenge-desktop
elif [ "$desktop" = "Mate" ]
    then pacstrap /mnt mate mate-extra mate-revenge-desktop
elif [ "$desktop" = "i3" ]
    then pacstrap /mnt i3-revenge-desktop
fi

# starting desktop manager
if [ "$desktop" = "Gnome" ]
    then arch_chroot "systemctl enable gdm.service"
else
    pacstrap /mnt lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
    arch_chroot "systemctl enable lightdm.service"
    rm -rf /mnt/etc/lightdm
    cp -r /etc/lightdm /mnt/etc/lightdm
fi

# enabling network manager
arch_chroot "systemctl enable NetworkManager"

# installing bootloader
if [ "$grub" = "Yes" ]
    then
        if [ "$SYSTEM" = 'BIOS' ]
            then echo "# Installing Bootloader..."
            pacstrap /mnt grub
            arch_chroot "grub-install --target=i386-pc $grub_device"
            arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
        else
            echo "# Installing Bootloader..."


            if [ "$ans" = "Automatic Partitioning" ]
                then root_part=${dev}2
            fi

            [[ $(echo $root_part | grep "/dev/mapper/") != "" ]] && bl_root=$root_part \
            || bl_root=$"PARTUUID="$(blkid -s PARTUUID ${root_part} | sed 's/.*=//g' | sed 's/"//g')

            arch_chroot "bootctl --path=/boot install"
            echo -e "default  Revenge\ntimeout  10" > /mnt/boot/loader/loader.conf
            [[ -e /mnt/boot/initramfs-linux.img ]] && echo -e "title\tArch Linux\nlinux\t/vmlinuz-linux\ninitrd\t/initramfs-linux.img\noptions\troot=${bl_root} rw" > /mnt/boot/loader/entries/Revenge.conf
        fi
fi  


# running mkinit
echo "# Running mkinitcpio..."
arch_chroot "mkinitcpio -p linux"

# unmounting partitions
umount -R /mnt

echo "# Installation Finished!" 
) | zenity --progress --title="$title" --width=450 --pulsate --no-cancel
}

# Adapted from AIS. An excellent bit of code!
arch_chroot() {
    arch-chroot /mnt /bin/bash -c "${1}"
}

# Adapted from Feliz Installer
Parted() {
	parted --script $dev "$1"
}

logo="revenge_logo_sm.png"

greeting
partitions
config1
config2
desktop
confirm
vbox
bootloader
installing









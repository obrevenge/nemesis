#!/bin/bash

rm nemesis.conf
rm mountpoints
rm mounts
rm config1.txt
rm config2.txt
rm .passwd

title="Nemesis Installer"

greeting() {
    yad --width=600 --height=400 --center --title="$title" --image="crosshairs.png" --image-on-top --form --field=" ":LBL --image-on-top --field="<big>Welcome to the Nemesis Installer</big>\n\nThank you for Choosing a Revenge OS System. Click Okay to Get Started":LBL --field="Type of Installation":CB --separator=" " "" "" "Normal!OEM!StationX OEM" > answer.txt

    type=` cat answer.txt | awk '{print $1;}' `
    
}
                                                   
partitions() {
    yad --width=600 --height=400 --center --title="$title" --text="Partitions" --text="<big>Partitioning</big>\n\nHow Would You Like to Partition Your Disk? Auto Partitioning will delete everything on the disk and install Revenge OS\n\nManual Partitioning will allow you to create and edit partitions and choose where to install Revenge OS" --image="$logo" --radiolist --list --column="Select" --column="Type" false "Automatic Partioning" false "Manual Partitioning" --separator=" " > answer.txt   

    part=` cat answer.txt | awk '{print $2;}' `

    if [ "$part" == "Manual" ]
        then echo "partition=\"manual\"" >> nemesis.conf
        gparted
        partitions=` fdisk -l | grep dev | grep -v Disk | awk '{print $1}' `
        fields=$(for i in $(echo $partitions)
            do
                echo "--field=${i}:CB"
            done)
            mounts=$(yad --width=600 --height=500 --center --title="$title" --text="What Partitions Do You Want to Use?\nSelect a Mount Point for Each Partition that You want to Use." --image="$logo" --separator=" " --form $fields \
            "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap" "NA!/!/boot!/home!/var!/data!/media!swap")
        
            rm mounts.txt
            for m in $(echo $mounts)
                do
                    num="1"
                    echo "/mnt$m" >> mounts.txt
                    num="$num + 1"
                done
        
            rm mountpoints.txt
            echo "#!/bin/bash" > mountpoints
            for i in $(echo $partitions)
                do
                    line=$(head -n 1 mounts.txt)
                    echo "mount $i $line" >> mountpoints
                    tail -n +2 mounts.txt > mounts.txt.tmp && mv mounts.txt.tmp mounts.txt
                done
                
            #mounting root partition
            root_part=` cat mountpoints | grep -v '/boot' | grep -v '/home' | grep -v 'NA' | grep -v '/var' | grep -v '/data' | grep -v '/media' | grep -v 'swap' | awk '{print $2;}' `
            mount $root_part /mnt
            
            # removing  un-selecting partions from file
            sed -i '/NA/d' mountpoints
            
            # checking for boot partition selection
            if [[ $(cat mountpoints | grep -i 'boot') != "" ]];then 
                  mkdir /mnt/boot
                  # mounting boot partition
                  boot=` cat mountpoints | grep -i '/boot' | awk '{print $2;}' `
                  mount $boot /mnt/boot
            fi
            
            # checking for home partition selection
            if [[ $(cat mountpoints | grep -i 'home') != "" ]];then 
                  mkdir /mnt/home
                  # mounting home partition
                  home=` cat mountpoints | grep -i '/home' | awk '{print $2;}' `
                  mount $home /mnt/home
            fi
            
            # checking for var partition selection
            if [[ $(cat mountpoints | grep -i 'var') != "" ]];then 
                  mkdir /mnt/var
                  # mounting var partition
                  var=` cat mountpoints | grep -i '/var' | awk '{print $2;}' `
                  mount $var /mnt/var
            fi
            
            # checking for data partition selection
            if [[ $(cat mountpoints | grep -i 'data') != "" ]];then 
                  mkdir /mnt/data
                  # mounting data partition
                  data=` cat mountpoints | grep -i '/data' | awk '{print $2;}' `
                  mount $data /mnt/data
            fi
            
            # checking for media partition selection
            if [[ $(cat mountpoints | grep -i 'media') != "" ]];then 
                  mkdir /mnt/media
                  # mounting media partition
                  media=` cat mountpoints | grep -i '/media' | awk '{print $2;}' `
                  mount $media /mnt/media
            fi

            # checking for swap partition selection
            if [[ $(cat mountpoints | grep -i 'swap') != "" ]];then 
                swapspace=` cat mountpoints | grep -i 'swap' | awk '{print $2;}' `
                mkswap $swapspace
                swapon $swapspace
                sed -i '/swap/d' mountpoints
            fi   
           
           # offering to create swapfile on /
           zenity --question --title="$title" --text "Would you like to create a 1GB swapfile on root?\nIf you've already mounted a swap partition or don't want swap, select \"No\".\nThis process could take some time, so please be patient." --height=40
            if [ "$?" = "0" ]
            then swapfile="yes"
            (echo "# Creating swapfile..."
            touch /mnt/swapfile
            dd if=/dev/zero of=/mnt/swapfile bs=1M count=1024
            chmod 600 /mnt/swapfile
            mkswap /mnt/swapfile
            swapon /mnt/swapfile) | zenity --progress --title="$title" --width=450 --pulsate --auto-close --no-cancel
            fi

		elif [ "$part" == "Automatic" ]
			then
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

        

    fi
}

config1(){
    locales=$(cat /etc/locale.gen | grep -v "#  " | sed 's/#//g' | sed 's/ UTF-8//g' | grep .UTF-8 | sort | awk '{ printf "!""\0"$0"\0" }')

    zones=$(cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sed "s/\/.*//g" | sort -ud | sort | awk '{ printf "!""\0"$0"\0" }')

    yad --width=600 --height=400 --center --title="$title" --image="$logo" --text "Configuration" --form --field="Select Your Keyboard Layout:":CB --field="Select Your locale:":CB --field="Select Your Region:":CB --separator=" " \
    "us!af!al!am!at!az!ba!bd!be!bg!br!bt!bw!by!ca!cd!ch!cm!cn!cz!de!dk!ee!es!et!eu!fi!fo!fr!gb!ge!gh!gn!gr!hr!hu!ie!il!in!iq!ir!is!it!jp!ke!kg!kh!kr!kz!la!lk!lt!lv!ma!md!me!mk!ml!mm!mn!mt!mv!ng!nl!no!np!pc!ph!pk!pl!pt!ro!rs!ru!se!si!sk!sn!sy!tg!th!tj!tm!tr!tw!tz!ua!uz!vn!za" "en_US.UTF-8 $locales" "$zones" > config1.txt

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

    yad --width=600 --height=400 --center --title="$title" --image="$logo" --text "Configuration" --form --field="Select your sub-zone:":CB --field="Use UTC or Local Time?":CB --field="Choose a hostname:" --field="Choose a username:" --field="Enter Your User Password:H" --field="Re-enter Your User Password:H" --field="Install Bootloader?":CB --separator=" " \
    "$subzones" "!UTC!Localtime" "" "" "" "" "yes!no"> config2.txt

    subzone=` cat config2.txt | awk '{print $1;}' `
    clock=` cat config2.txt | awk '{print $2;}' `
    hname=` cat config2.txt | awk '{print $3;}' `
    username=` cat config2.txt | awk '{print $4;}' `
    rtpasswd1=` cat config2.txt | awk '{print $5;}' `
    rtpasswd2=` cat config2.txt | awk '{print $6;}' `
    grub=` cat config2.txt | awk '{print $7;}' `

    if [ "$rtpasswd1" != "$rtpasswd2" ]
            then zenity --error --title="$title" --text "The passwords did not match, please try again." --height=40
            config2
    fi

    if [[ "$username" =~ [A-Z] ]];then
	    zenity --error --title="$title" --text "Your username must be in all lowercase, please try again." --height=40
            config2
    fi

    if [[ "$hname" =~ [A-Z] ]];then
	    zenity --error --title="$title" --text "Your hostname must be in all lowercase, please try again." --height=40
            config2
    fi

    lsblk -lno NAME,TYPE | grep 'disk' | awk '{print "/dev/" $1 " " $2}' | sort -u > devices.txt
sed -i 's/\<disk\>//g' devices.txt
devices=` awk '{print "FALSE " $0}' devices.txt `

    if [ "$grub" = "yes" ]
	then grub_device=$(zenity --list --title="$title" --text "Where do you want to install the bootloader?" --radiolist --column Select --column Device $devices)
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

grub=$(zenity --list --radiolist --title="$title" --text "Would you like to install the bootloader?\nThe answer to this is usually yes,\nunless you are dual-booting and plan to have another system handle\nthe boot process." --column="Select" --column="Answer" FALSE yes FALSE no) 
if [ "$grub" = "yes" ]
	then grub_device=$(zenity --list --title="$title" --text "Where do you want to install the bootloader?" --radiolist --column Select --column Device $devices)
fi
}

confirm() {
    zenity --width=600 --question --title="$title" --text="You have chosen the following:\n\n$part partitioning\n\nKeyboard layout: $key\n\nTimezone: $zone $subzone\n\nHostname: $hname\n\nUsername: $username\n\nClock configuration: $clock\n\nDesktop: $desktop\n\nIf the above options are correct, click 'Yes' to continue.\nIf you need to make changes, click 'No' to start over."

    
    if [ "$?" = "1" ]
        then ans=$(zenity --list --radiolist --title="$title" --text "What would you like to do now?" --column Select --column Option FALSE "Cancel" FALSE "Start Over")
		if [ "$ans" = "Cancel" ]
			then exit
		elif [ "$ans" = "Start Over" ]
			then greeting
		else exit
		fi
    fi 
    
}

auto_partition() {
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
			
}

installing() {

if [ "$part" == "Automatic" ]
    then auto_partition
fi

# sorting pacman mirrors
echo "15"
echo "# Sorting fastest pacman mirrors..."
reflector --verbose -l 50 -p http --sort rate --save /etc/pacman.d/mirrorlist

# updating pacman cache
echo "# Updating Pacman Cache..."
pacman -Syy
arch_chroot "pacman -Syy"

#installing base
echo "20"
echo "# Installing Base..."
pacstrap /mnt base base-devel

#fixing pacman.conf
rm -f /mnt/etc/pacman.conf
cp /etc/pacman.conf /mnt/etc/pacman.conf


#generating fstab
echo "50"
echo "# Generating File System Table..."
genfstab -p /mnt >> /mnt/etc/fstab
if grep -q "/mnt/swapfile" "/mnt/etc/fstab"; then
sed -i '/swapfile/d' /mnt/etc/fstab
echo "/swapfile		none	swap	defaults	0	0" >> /mnt/etc/fstab
fi

#setting locale
echo "LANG=\"${locale}\"" > /mnt/etc/locale.conf
sed -i "s/#${locale}/${locale}/g" /mnt/etc/locale.gen
arch_chroot "locale-gen"
export LANG=${locale}

#setting keymap
mkdir -p /mnt/etc/X11/xorg.conf.d/
echo -e 'Section "InputClass"\n	Identifier "system-keyboard"\n	MatchIsKeyboard "on"\n	Option "XkbLayout" "'$key'"\n	Option "XkbModel" "'$model'"\n	Option "XkbVariant" ",'$variant'"\n	 Option "XkbOptions" "grp:alt_shift_toggle"\nEndSection' > /mnt/etc/X11/xorg.conf.d/00-keyboard.conf

#setting timezone
echo "60"
echo "# Setting Timezone..."
arch_chroot "rm /etc/localtime"
arch_chroot "ln -s /usr/share/zoneinfo/${zone}/${subzone} /etc/localtime"

#setting hw clock
arch_chroot "hwclock --systohc --$clock"

#setting hostname
arch_chroot "echo $hname > /etc/hostname"

# setting sudo permissions
echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers

# installing video and audio packages
echo "70"
echo "# Installing Sound, and Video Drivers..."
pacstrap /mnt  mesa xorg-server xorg-apps xorg-xinit xorg-drivers xterm alsa-utils pulseaudio pulseaudio-alsa xf86-input-synaptics xf86-input-keyboard xf86-input-mouse xf86-input-libinput intel-ucode b43-fwcutter networkmanager nm-connection-editor network-manager-applet polkit-gnome gksu ttf-dejavu gnome-keyring xdg-user-dirs gvfs libmtp gvfs-mtp wpa_supplicant dialog iw reflector rsync mlocate bash-completion htop unrar p7zip yad yaourt polkit-gnome lynx wget zenity gksu squashfs-tools ntfs-3g gptfdisk cups ghostscript gsfonts linux-headers dkms broadcom-wl-dkms revenge-lsb-release

# virtualbox
if [ "$vbox" = "yes" ]
	then pacstrap /mnt virtualbox-guest-modules-arch virtualbox-guest-utils
    echo -e "vboxguest\nvboxsf\nvboxvideo" > /mnt/etc/modules-load.d/virtualbox.conf
fi

# installing chosen desktop
echo "80"
echo "# Installing Chosen Desktop..."
if [ "$desktop" = "Gnome" ]
    then pacstrap /mnt gnome gnome-extra gnome-revenge-desktop
    # setting xorg as default session
    sed -i 's/#WaylandEnable=false/WaylandEnable=false/g' /mnt/etc/gdm/custom.conf 
elif [ "$desktop" = "OBR" ]
    then pacstrap /mnt obr-desktop surfn-icons-git
elif [ "$desktop" = "Plasma" ]
    then pacstrap /mnt plasma plasma-revenge-desktop
elif [ "$desktop" = "XFCE" ]
    then pacstrap /mnt xfce4 xfce4-goodies xfce-revenge-desktop
elif [ "$desktop" = "Mate" ]
    then pacstrap /mnt mate mate-extra mate-revenge-desktop mate-tweak brisk-menu plank mate-applet-dock mate-menu mate-netbook synapse tilda topmenu-gtk blueman metacity
elif [ "$desktop" = "i3" ]
    then pacstrap /mnt i3-revenge-desktop lxsession
    sed -i "s|zone|${zone}/${subzone}|g" /mnt/etc/skel/.config/i3status/config
fi

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
echo "90"
echo "# Making new user..."
if [ "$type" = "Normal" ]
    then
    arch_chroot "useradd -m -g users -G adm,lp,wheel,power,audio,video -s /bin/bash $username"
    arch_chroot "passwd $username" < .passwd >/dev/null
    rm .passwd
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
    elif [ "$desktop" = "Plasma" ]
        then sed -i 's/openbox-session/startkde/g' /mnt/root/.xinitrc
    elif [ "$desktop" = "XFCE" ]
        then sed -i 's/openbox-session/startxfce4/g' /mnt/root/.xinitrc
    elif [ "$desktop" = "Mate" ]
        then sed -i 's/openbox-session/mate-session/g' /mnt/root/.xinitrc
    elif [ "$desktop" = "i3" ]
        then sed -i 's/openbox-session/i3/g' /mnt/root/.xinitrc
    fi

fi    


# starting desktop manager
if [ "$type" = "Normal" ];then

    if [ "$desktop" = "Gnome" ]
        then arch_chroot "systemctl enable gdm.service"
    else
        pacstrap /mnt lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
        arch_chroot "systemctl enable lightdm.service"
        echo "theme-name = BlackMATE" >> /mnt/etc/lightdm/lightdm-gtk-greeter.conf
        echo "background = /usr/share/Wallpaper/Shadow_cast-RevengeOS-v2.png" >> /mnt/etc/lightdm/lightdm-gtk-greeter.conf
    fi
fi

# enabling network manager
arch_chroot "systemctl enable NetworkManager"


# fixing revenge branding
rm -f /mnt/etc/os-release
cp os-release /mnt/etc/os-release

# running mkinit
echo "95"
echo "# Running mkinitcpio..."
arch_chroot "mkinitcpio -p linux"

if [ "$type" = "StationX" ]
    then # installing stationx wallpapers
	pacstrap /mnt revenge-stationx-wallpapers
fi

# installing bootloader
if [ "$grub" = "yes" ]
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
        if [ "$desktop" = "Plasma" ]
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

echo "# Installation Finished!" 

}

# System Detection
if [[ -d "/sys/firmware/efi/" ]]; then
      SYSTEM="UEFI"
      else
      SYSTEM="BIOS"
fi

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
#bootloader
(installing) | zenity --progress --title="$title" --width=450 --no-cancel

if [ "$type" = "StationX" ];then
	zenity --info --height=40 --text "When you reboot the system you will be auto-logged in as root.\nYou may install any extra packages, or make\nany extra cofigurations that you like.\nWhen you are finished, either click the dialog box that appears on boot,\n or run 'oem-setup live' in a terminal to finalize\nthe install and prepare for the end user's first boot."
fi

if [ "$type" = "OEM" ];then
	zenity --info --height=40 --text "When you reboot the system you will be auto-logged in as root.\nYou may install any extra packages, or make\nany extra cofigurations that you like.\nWhen you are finished, either click the dialog box that appears on boot,\n or run 'oem-setup live' in a terminal to finalize\nthe install and prepare for the end user's first boot."
fi









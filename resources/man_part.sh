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
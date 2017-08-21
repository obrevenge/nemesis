#!/bin/bash

yad --width=600 --height=400 --center --title="$title" --image="crosshairs.png" --image-on-top --form --field=" ":LBL --image-on-top --field="<big>Welcome to the Nemesis Installer</big>\n\nThank you for Choosing a Revenge OS System. Click Okay to Get Started":LBL --field="Type of Installation":CB --separator=" " "" "" "Normal!OEM" > answer.txt

    type=` cat answer.txt | awk '{print $1;}' `
    
if [ "$type" = "Normal" ]
    then echo "normal"
elif [ "$type" = "OEM" ]
    then echo "oem"
else
    echo "other"
fi

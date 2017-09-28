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


graphics=$(lspci | grep -i "vga" | sed 's/.*://' | sed 's/(.*//' | sed 's/^[ \t]*//')
if [[ $(echo $graphics | grep -i 'virtualbox') != "" ]]
	then vbox="yes"
fi

if [ "$vbox" = "yes" ]
	then pacstrap /mnt virtualbox-guest-dkms virtualbox-guest-utils
    echo -e "vboxguest\nvboxsf\nvboxvideo" > /mnt/etc/modules-load.d/virtualbox.conf
fi

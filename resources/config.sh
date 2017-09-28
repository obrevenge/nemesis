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

#setting locale
echo "LANG=\"${locale}\"" > /mnt/etc/locale.conf
sed -i "s/#${locale}/${locale}/g" /mnt/etc/locale.gen
arch_chroot "locale-gen"
export LANG=${locale}

#setting keymap
mkdir -p /mnt/etc/X11/xorg.conf.d/
echo -e 'Section "InputClass"\n	Identifier "system-keyboard"\n	MatchIsKeyboard "on"\n	Option "XkbLayout" "'$key'"\n	Option "XkbModel" "'$model'"\n	Option "XkbVariant" ",'$variant'"\n	 Option "XkbOptions" "grp:alt_shift_toggle"\nEndSection' > /mnt/etc/X11/xorg.conf.d/00-keyboard.conf

#setting timezone
arch_chroot "rm /etc/localtime"
arch_chroot "ls -sf /usr/share/zoneinfo/${timezone} /etc/localtime"

#setting hostname
arch_chroot "echo $hname > /etc/hostname"

# setting sudo permissions
echo "%wheel ALL=(ALL) ALL" >> /mnt/etc/sudoers
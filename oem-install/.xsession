#!/bin/sh

#
# ~/.xsession
#
# Executed by xdm/gdm/kdm at login
#

export GTK_CSD=0

/bin/bash --login -i ~/.xinitrc


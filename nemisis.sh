#!/bin/bash

sudo pacman -U --noconfirm tzupdate-1.2.0-1-any.pkg.tar.xz

sudo cp -r resources/gtk-3.0/ /root/.config/

sudo ./nemesisv2.py
#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

[ -f ~/.xprofile ] && source ~/.xprofile

/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
thunar --daemon &
run_once xfce4-power-manager &
(sleep 25 && run_once mpdas) &


DEFAULT_SESSION="awesome"

case $1 in
awesome)
	exec awesome
	;;
openbox)
	exec openbox-session
	;;
gnome)
    exec gnome-session
    ;;
*)
	exec $DEFAULT_SESSION
	;;
esac

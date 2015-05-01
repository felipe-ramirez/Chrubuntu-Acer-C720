#!/bin/bash

NOW=$(date +"%Y%m%d%H%M")

###
### Download and install custom kernel with touchpad fixes.
###
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.17-utopic/linux-image-3.17.0-031700-generic_3.17.0-031700.201410060605_amd64.deb
dpkg -i linux-image-3.17.0-031700-generic_3.17.0-031700.201410060605_amd64.deb
rm linux-image-3.17.0-031700-generic_3.17.0-031700.201410060605_amd64.deb


###
### Hold back the custom kernel so it doesn't updated.
###
apt-mark hold linux-image-3.17.0-031700-generic


###
### Create 05_sound file under /etc/pm/sleep.d
###
cat >/etc/pm/sleep.d/05_sound <<EOL
#!/bin/sh
case "\${1}" in
   hibernate|suspend)
      # Unbind ehci for preventing error
      echo -n "0000:00:1d.0" | tee /sys/bus/pci/drivers/ehci-pci/unbind
      # Unbind snd_hda_intel for sound
      echo -n "0000:00:1b.0" | tee /sys/bus/pci/drivers/snd_hda_intel/unbind
      echo -n "0000:00:03.0" | tee /sys/bus/pci/drivers/snd_hda_intel/unbind
   sleep 1
   ;;
   resume|thaw)
      # Bind ehci for preventing error
      echo -n "0000:00:1d.0" | tee /sys/bus/pci/drivers/ehci-pci/bind
      # Bind snd_hda_intel for sound
      echo -n "0000:00:1b.0" | tee /sys/bus/pci/drivers/snd_hda_intel/bind
      echo -n "0000:00:03.0" | tee /sys/bus/pci/drivers/snd_hda_intel/bind
   sleep 1
   ;;
esac
EOL

chmod +x /etc/pm/sleep.d/05_sound


###
### Edit /etc/rc.local
###
cp /etc/rc.local /etc/rc.local-$NOW
cat >/etc/rc.local <<EOL
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

echo EHCI > /proc/acpi/wakeup
echo HDEF > /proc/acpi/wakeup
echo XHCI > /proc/acpi/wakeup
echo LID0 > /proc/acpi/wakeup
echo TPAD > /proc/acpi/wakeup
echo TSCR > /proc/acpi/wakeup
echo 300 > /sys/class/backlight/intel_backlight/brightness
rfkill block bluetooth
/etc/init.d/bluetooth stop

exit 0
EOL


###
### Edit and update grub
###
cp /etc/default/grub /etc/default/grub-$NOW
cat >/etc/default/grub <<EOL
# If you change this file, run 'update-grub' afterwards to update
# /boot/grub/grub.cfg.
# For full documentation of the options in this file, see:
#   info -f grub -n 'Simple configuration'

GRUB_DEFAULT=0
#GRUB_HIDDEN_TIMEOUT=0
#GRUB_HIDDEN_TIMEOUT_QUIET=true
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR=\`lsb_release -i -s 2> /dev/null || echo Debian\`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash tpm_tis.force=1"
GRUB_CMDLINE_LINUX=""

# Uncomment to enable BadRAM filtering, modify to suit your needs
# This works with Linux (no patch required) and with any kernel that obtains
# the memory map information from GRUB (GNU Mach, kernel of FreeBSD ...)
#GRUB_BADRAM="0x01234567,0xfefefefe,0x89abcdef,0xefefefef"

# Uncomment to disable graphical terminal (grub-pc only)
#GRUB_TERMINAL=console

# The resolution used on graphical terminal
# note that you can use only modes which your graphic card supports via VBE
# you can see them in real GRUB with the command \`vbeinfo'
#GRUB_GFXMODE=640x480

# Uncomment if you don't want GRUB to pass "root=UUID=xxx" parameter to Linux
#GRUB_DISABLE_LINUX_UUID=true

# Uncomment to disable generation of recovery mode menu entries
#GRUB_DISABLE_RECOVERY="true"

# Uncomment to get a beep at grub start
#GRUB_INIT_TUNE="480 440 1"

EOL

update-grub


###
### Create a sound suspend file in /usr/lib/systemd
###
mkdir /usr/lib/systemd/system-sleep
cat >/usr/lib/systemd/system-sleep/cros-sound-suspend.sh <<EOL
#!/bin/bash
case \$1/\$2 in
   pre/*)
      # Unbind ehci for preventing error
      echo -n "0000:00:1d.0" | tee /sys/bus/pci/drivers/ehci-pci/unbind
      # Unbind snd_hda_intel for sound
      echo -n "0000:00:1b.0" | tee /sys/bus/pci/drivers/snd_hda_intel/unbind
      echo -n "0000:00:03.0" | tee /sys/bus/pci/drivers/snd_hda_intel/unbind
   ;;
   post/*)
      # unBind ehci for preventing error
      echo -n "0000:00:1d.0" | tee /sys/bus/pci/drivers/ehci-pci/unbind
      # bind snd_hda_intel for sound
      echo -n "0000:00:1b.0" | tee /sys/bus/pci/drivers/snd_hda_intel/bind
      echo -n "0000:00:03.0" | tee /sys/bus/pci/drivers/snd_hda_intel/bind
   ;;
esac
EOL


###
### Install packages to enable hotkeys
###
apt-get install -y xbindkeys xbacklight xvkbd


### Create .xbindkeysrc under /etc/skel/
cat >/etc/skel/.xbindkeysrc <<EOL
# Backward, Forward, Full Screen & Refresh is just for web browser
#Backward
"xvkbd -xsendevent -text "\\A\\[Left]""
    m:0x0 + c:67
    F1

#Full Screen
"xvkbd -xsendevent -text "\\[F11]""
    m:0x0 + c:70
    F4

#Forward
"xvkbd -xsendevent -text "\\A\\[Right]""
    m:0x0 + c:68
    F2

#Refresh
"xvkbd -xsendevent -text "\\Cr""
    m:0x0 + c:69
    F3

# on ChromeBook, it "Enter Overview mode, which shows all windows (F5)", see also https://support.google.com/chromebook/answer/1047364?hl
# here it work at KDE, it "Switch to next focused window", see also http://community.linuxmint.com/tutorial/view/47
#Switch Window
"xvkbd -xsendevent -text "\\A\\t""
    m:0x0 + c:71
    F5

#Backlight Down
"xbacklight -dec 5"
    m:0x0 + c:72
    F6

#Backlight Up
"xbacklight -inc 5"
    m:0x0 + c:73
    F7

#Mute
"amixer -D pulse set Master toggle"
    m:0x0 + c:74
    F8

#Decrease Volume
"amixer -c 1 set Master 5- unmute"
    m:0x0 + c:75
    F9

#Increase Volume
"amixer -c 1 set Master 5+ unmute"
    m:0x0 + c:76
    F10

# added Home, End, Pg Up, Pg Down, and Del keys using the Alt+arrow key combos
#Delete
"xvkbd -xsendevent -text '\\[Delete]'"
    m:0x8 + c:22
    Alt + BackSpace

#End
"xvkbd -xsendevent -text '\\[End]'"
    m:0x8 + c:114
    Alt + Right

#Home
"xvkbd -xsendevent -text '\\[Home]'"
    m:0x8 + c:113
    Alt + Left

#Page Down
"xvkbd -xsendevent -text '\\[Page_Down]'"
    m:0x8 + c:116
    Alt + Down

#Page Up
"xvkbd -xsendevent -text '\\[Page_Up]'"
    m:0x8 + c:111
    Alt + Up
EOL 


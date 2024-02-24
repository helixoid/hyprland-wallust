Install plymouth and set plymouth theme
$ paru -S plymouth
$ sudo plymouth-set-default-theme bgrt

Add the kernel parameters
$ sudo nano /etc/kernel/cmdline
nano add to the start of the line: quiet splash

Enabling plymouth splash screen
First Time after Install: $ sudo reinstall-kernels
Changing the theme: $ sudo dracut-rebuild
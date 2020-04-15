# gala-layoutpw-plugin
Gala plugin to switch layouts per window

The plugin is in a testing state. As long as it's always on. Hopefully a switch will be added to the switchboard-plug-keyboard in the future.

## Notice
if you are using version >0.3.0, you need to enable "org.gnome.desktop.input-sources.per-window"
The schema has changed for the master branch. Be careful) "org.pantheon.desktop.gala.layout-per-window" (value: none | application | window)

Works with mutter-3.28, mutter-3.30, mutter-3.34

## Building and Installation

You'll need the following dependencies to build:
* valac
* libglib2.0-dev
* libgee-0.8-dev
* libgala-dev
* meson

## How To Build
### If you are using debian, ubuntu add --libdir=/usr/lib/x86_64-linux-gnu on the first step
    meson build --prefix=/usr
    ninja -C build
    sudo ninja -C build install

## Enable the plugin (none | application | window)
    gsettings set org.pantheon.desktop.gala.layout-per-window save-type application
## Restore after a reboot (actual only for applications)
    gsettings set org.pantheon.desktop.gala.layout-per-window restore true

## if something went wrong

    cd [your lib directory]/gala/plugins
    sudo rm libgala-layoutpw.so
    reboot

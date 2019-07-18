# gala-layoutpw-plugin
Gala plugin to switch layouts per window

The plugin is in a testing state. As long as it's always on. Hopefully a switch will be added to the switchboard-plug-keyboard in the future.

Works with mutter-3.28 and mutter-3.30

## Building and Installation

You'll need the following dependencies to build:
* valac
* libglib2.0-dev
* libgee-0.8-dev
* libgala-dev
* meson

## How To Build

    meson build --prefix=/usr //debian,ubuntu --libdir=/usr/lib/x86_64-linux-gnu
    ninja -C build
    sudo ninja -C build install

## if something went wrong

    cd [your lib directory]/gala/plugins
    sudo rm libgala-layoutpw.so
    reboot

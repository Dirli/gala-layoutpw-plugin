# gala-layoutpw-plugin
Gala plugin to switch layouts per window

<p align="left">
    <a href="https://paypal.me/Dirli85">
        <img src="https://img.shields.io/badge/Donate-PayPal-green.svg">
    </a>
</p>

----

## Notice
if you are using version 0.3.1, you need to enable "org.gnome.desktop.input-sources.per-window"

## Building and Installation

### You'll need the following dependencies to build:
* valac
* libglib2.0-dev
* libgee-0.8-dev
* libgala-dev
* meson

### How to build
    meson build --prefix=/usr
    ninja -C build
    sudo ninja -C build install

## Enable the plugin (none | application | window)
    gsettings set org.pantheon.desktop.gala.layout-per-window save-type application

## Restore after a reboot (actual only for applications)
    gsettings set org.pantheon.desktop.gala.layout-per-window restore true

## If something went wrong
    cd [your_lib_directory]/gala/plugins
    sudo rm libgala-layoutpw.so
    reboot

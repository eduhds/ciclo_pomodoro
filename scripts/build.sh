#!/bin/sh

app_name=ciclo_pomodoro

if [ "$1" = "--web" ]; then
    # Build web
    flutter build web --base-href "/$app_name/"
elif [ "$1" = "--linux" ]; then
    # Build Linux
    flutter build linux --release
    
    if [ $? -ne 0 ]; then
        exit 1
    fi

    rm -rf linux/AppDir 2> /dev/null || true && mkdir linux/AppDir
    mkdir -p linux/AppDir/usr && mkdir -p linux/AppDir/usr/bin

    cp -r build/linux/x64/release/bundle/{data,lib} linux/AppDir/usr/bin

    linuxdeploy --appdir linux/AppDir \
        --executable build/linux/x64/release/bundle/$app_name \
        --icon-file linux/$app_name.png \
        --desktop-file linux/$app_name.desktop \
        --output appimage
fi
